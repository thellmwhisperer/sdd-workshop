#!/bin/sh
# The workshop's guard: a Copilot preToolUse hook (.github/hooks/workshop.json) that turns
# the rules the chief broke in rehearsals into code. It reads the tool call as JSON on
# stdin and, to refuse it, prints {"permissionDecision":"deny",...}. Anything else passes.
# Copilot loads it for every session in the repository, the chief's and a worker's alike
# (31 October: a worker lost minutes rewording a heredoc that named graph/run.sh). The
# rules are the chief's, so a worker, which graph/worker.sh and graph/copilot.sh launch
# with WORKSHOP_WORKER=1, is let through.
# Usage (by Copilot): sh workshop/hooks/guard.sh < tool-call.json
set -u
if [ -n "${WORKSHOP_WORKER:-}" ]; then exit 0; fi
here=$(cd "$(dirname "$0")" && pwd)
input=$(cat)

deny() {
  # The reason goes inside a JSON string: no double quotes or backslashes in it.
  printf '{"permissionDecision":"deny","permissionDecisionReason":"%s"}\n' "$1"
  exit 0
}
has() { printf '%s' "$input" | grep -Eq "$1"; }

session=$(printf '%s' "$input" | sed -n 's/.*"sessionId":"\([^"]*\)".*/\1/p' | head -n 1)
panel="$here/.panel/${session:-unknown}"

watch='Open it in the terminal panel instead, so the group watches it live: open_canvas with canvasId terminal and input.command'
follow='Then follow it with invoke_canvas_action read_terminal_output and say one line to the group after each look (COS.md, Delegate and supervise).'

# 1. A worker is never an invisible subagent.
if has '"toolName":"task"'; then
  deny "Workers are never launched with the task tool: the group could not see them. $watch cd <absolute group folder> && sh graph/worker.sh tickets/<ticket>.md . $follow"
fi

if has '"toolName":"bash"'; then
  # 2. A worker or a run is never a command in a card or in the background.
  if has '(sh|bash)[[:space:]]+([^[:space:]"]*/)?graph/worker\.sh|\./graph/worker\.sh|copilot[[:space:]]+(-p|--prompt)'; then
    deny "A worker is never launched from a command card. $watch cd <absolute group folder> && sh graph/worker.sh tickets/<ticket>.md . $follow"
  fi
  if has '(sh|bash)[[:space:]]+([^[:space:]"]*/)?graph/run\.sh|\./graph/run\.sh'; then
    deny "A run is never launched from a command card. $watch cd <absolute group folder> && sh graph/run.sh tickets/<ticket>.md . Read where it is with sh graph/state.sh graph/runs/<run>. $follow"
  fi
  # 3. Never sleep while something runs.
  if has 'sleep[[:space:]]+([5-9]|[1-9][0-9])'; then
    deny 'Never sleep while something runs: the group sits in silence. Say something to the group first, then look: read the terminal panel with read_terminal_output, or a short tail of the log (COS.md, Never sleep).'
  fi
  # 4. Nothing the group should see goes outside its folder.
  if has '/tmp/|/private/tmp|/var/folders'; then
    deny 'Nothing goes to /tmp or /var/folders: the group only sees its own folder. Write it under graph/runs/ in the group folder (COS.md, Transparency).'
  fi
fi

# 5. The contract is open in the panel before its ticket is written.
if has '"toolName":"open_canvas"'; then
  path=$(printf '%s' "$input" | sed -n 's/.*"path":"\([^"]*\)".*/\1/p' | head -n 1)
  if [ -n "$path" ]; then
    mkdir -p "$here/.panel"
    printf '%s\n' "$path" >> "$panel"
  fi
fi
if has '"toolName":"(edit|create|write|str_replace_editor)"'; then
  opened() { [ -f "$panel" ] && grep -q "$1\$" "$panel"; }
  if has '"path":"[^"]*tickets/000-node\.md"' && ! opened 'graph/NODE.md'; then
    deny 'Open graph/NODE.md in the editor panel first (open_canvas, canvasId editor, input.path group-N/graph/NODE.md): the group reads the contract of the node before you write its ticket (COS.md, hour 2, step 1).'
  fi
fi
exit 0
