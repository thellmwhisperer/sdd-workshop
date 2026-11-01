package main

// events: a Copilot conversation, as Copilot writes it (one event per line: copilot.jsonl
// of a run step, events.jsonl of a chief's session), into the tables La Roca's corpus
// keeps a conversation in:
//
//	sessions         one row: the conversation, its kind, title, start and end
//	exchanges        one row per human turn: what the human said, what the agent answered,
//	                 when, the model, tokens, cost
//	tool_uses        one row per tool the agent called in that turn: its name, what it
//	                 asked for, whether it failed and why. What the tool gave back is not
//	                 kept, as in La Roca: it is the file or the output, not the conversation
//	thinking_blocks  one row per block the agent thought in that turn
//
//	vectors events <session_id> <kind> <title>   stdin: the events; stdout: the SQL

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"time"
)

type event struct {
	Type      string          `json:"type"`
	Timestamp string          `json:"timestamp"`
	Data      json.RawMessage `json:"data"`
}

type toolCall struct {
	ID        string         `json:"toolCallId"`
	Name      string         `json:"name"`
	ToolName  string         `json:"toolName"`
	Arguments map[string]any `json:"arguments"`
}

type tool struct {
	name, params, errorMessage string
	hadError                   bool
}

// exchange: one human turn and everything the agent did until the next one.
type exchange struct {
	human, humanAt, agentAt string
	agent, thinking         []string
	tools                   []*tool
	model                   string
	in, out                 int64
	cost                    float64
	usage                   bool
}

func events(session, kind, title string) {
	var turns []*exchange
	var cur *exchange
	open := map[string]*tool{}
	var first, last string

	sc := bufio.NewScanner(os.Stdin)
	sc.Buffer(make([]byte, 1<<20), 64<<20)
	for sc.Scan() {
		line := sc.Bytes()
		if len(line) == 0 || line[0] != '{' {
			continue
		}
		var e event
		if json.Unmarshal(line, &e) != nil {
			continue
		}
		at := when(e.Timestamp)
		if at != "" {
			if first == "" {
				first = at
			}
			last = at
		}
		if e.Type == "user.message" {
			var d struct {
				Content string `json:"content"`
			}
			json.Unmarshal(e.Data, &d)
			cur = &exchange{human: strings.TrimSpace(d.Content), humanAt: at}
			turns = append(turns, cur)
			continue
		}
		if cur == nil {
			continue
		}
		switch e.Type {
		case "assistant.message":
			var d struct {
				Content   string     `json:"content"`
				Reasoning string     `json:"reasoningText"`
				Requests  []toolCall `json:"toolRequests"`
			}
			json.Unmarshal(e.Data, &d)
			if t := strings.TrimSpace(d.Reasoning); t != "" {
				cur.thinking = append(cur.thinking, t)
			}
			if t := strings.TrimSpace(d.Content); t != "" {
				cur.agent = append(cur.agent, t)
				cur.agentAt = at
			}
			for _, c := range d.Requests {
				t := &tool{name: c.Name, params: params(c.Arguments)}
				cur.tools = append(cur.tools, t)
				open[c.ID] = t
			}
		case "tool.execution_start":
			var c toolCall
			json.Unmarshal(e.Data, &c)
			if _, ok := open[c.ID]; !ok && c.ID != "" {
				t := &tool{name: c.ToolName, params: params(c.Arguments)}
				cur.tools = append(cur.tools, t)
				open[c.ID] = t
			}
		case "tool.execution_complete":
			var d struct {
				ID      string `json:"toolCallId"`
				Success bool   `json:"success"`
				Error   *struct {
					Message string `json:"message"`
				} `json:"error"`
			}
			json.Unmarshal(e.Data, &d)
			if t, ok := open[d.ID]; ok && !d.Success {
				t.hadError = true
				t.errorMessage = "failed"
				if d.Error != nil && d.Error.Message != "" {
					t.errorMessage = d.Error.Message
				}
			}
			delete(open, d.ID)
		case "session.usage_record":
			var d struct {
				Usage struct {
					Model string  `json:"model"`
					In    int64   `json:"inputTokens"`
					Out   int64   `json:"outputTokens"`
					Cost  float64 `json:"cost"`
				} `json:"usage"`
			}
			json.Unmarshal(e.Data, &d)
			cur.usage = true
			cur.in += d.Usage.In
			cur.out += d.Usage.Out
			cur.cost += d.Usage.Cost
			if d.Usage.Model != "" {
				cur.model = d.Usage.Model
			}
		}
	}
	if err := sc.Err(); err != nil {
		fail(err)
	}

	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()
	fmt.Fprintf(out, "INSERT INTO sessions (session_id, kind, title, started_at, ended_at) VALUES (%s, %s, %s, %s, %s);\n",
		quote(session), quote(kind), quote(title), quote(first), quote(last))
	for i, x := range turns {
		n := i + 1
		tokensIn, tokensOut, cost := "NULL", "NULL", "NULL"
		if x.usage {
			tokensIn, tokensOut, cost = fmt.Sprint(x.in), fmt.Sprint(x.out), fmt.Sprintf("%g", x.cost)
		}
		fmt.Fprintf(out, "INSERT INTO exchanges (session_id, exchange_number, human_text, agent_text, human_timestamp, agent_timestamp, model, tokens_in, tokens_out, cost) VALUES (%s, %d, %s, %s, %s, %s, %s, %s, %s, %s);\n",
			quote(session), n, quote(x.human), quote(strings.Join(x.agent, "\n\n")), quote(x.humanAt), quote(x.agentAt),
			quote(x.model), tokensIn, tokensOut, cost)
		for _, t := range x.thinking {
			fmt.Fprintf(out, "INSERT INTO thinking_blocks (session_id, exchange_number, full_text) VALUES (%s, %d, %s);\n",
				quote(session), n, quote(t))
		}
		for _, t := range x.tools {
			had := 0
			if t.hadError {
				had = 1
			}
			fmt.Fprintf(out, "INSERT INTO tool_uses (session_id, exchange_number, tool_name, tool_params_summary, had_error, error_message) VALUES (%s, %d, %s, %s, %d, %s);\n",
				quote(session), n, quote(t.name), quote(t.params), had, quote(t.errorMessage))
		}
	}
}

// params: what a tool was asked for, in one line: the command, the file, or its arguments.
func params(args map[string]any) string {
	for _, k := range []string{"command", "path", "pattern", "url", "query"} {
		if v, ok := args[k].(string); ok && v != "" {
			return strings.Join(strings.Fields(v), " ")
		}
	}
	b, _ := json.Marshal(args)
	s := string(b)
	if len(s) > 400 {
		s = s[:400] + "…"
	}
	return s
}

// when: an event's time as "2026-10-31 20:22", in this laptop's time zone.
func when(ts string) string {
	t, err := time.Parse(time.RFC3339Nano, ts)
	if err != nil {
		return ""
	}
	return t.Local().Format("2006-01-02 15:04")
}

// quote: an SQL string literal.
func quote(s string) string { return "'" + strings.ReplaceAll(s, "'", "''") + "'" }
