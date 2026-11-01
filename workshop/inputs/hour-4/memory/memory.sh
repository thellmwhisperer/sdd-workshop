#!/bin/sh
# Memory for your graph, kept the way La Roca keeps an agent corpus: every conversation by
# who said what, and what the system wrote on disk.
#   sh memory/memory.sh index <folder>... [chief]   keep your day: graph/runs, notes, and
#                                                   with chief, your conversations with it
#   sh memory/memory.sh ask "<question>"            find it, by words and by meaning
#   sh memory/memory.sh eval "<question>"           the model without and with what ask finds
#   sh memory/memory.sh tables                      what is kept, and questions SQL answers
#   sh memory/memory.sh sql "<SELECT ...>"          ask the tables directly (read only)
#   ask --example, eval --example, sql --example    the example team, the rescue
#
# The tables (as La Roca's corpus):
#   sessions         one conversation: your chief's, or one agent step of a run
#   exchanges        one human turn and the agent's answer: human_text, agent_text, when,
#                    model, tokens, cost
#   tool_uses        each tool the agent called in that turn: name, what it asked for,
#                    whether it failed and why. What a tool gave back (a file, an output)
#                    is not kept, as in La Roca
#   thinking_blocks  what the agent thought in that turn, when the model shows it
#   memories         what the system wrote down: reports, pull requests, journals, the
#                    chief's notes, the decisions
# A Copilot conversation (copilot.jsonl of a run step, and your chief's sessions in
# ~/.copilot/session-state) is read by bin/vectors-<os>-<arch> events; Copilot's own
# exports of the same conversation (conversation.md, agent.log) are not read twice.
# By words: SQLite full-text search over what the human said, what the agent answered,
# what it thought, and the memories. By meaning: a small model on this laptop, MiniLM
# (minilm.bin, 23 MB), turns each text and the question into a vector; the closest mean
# the most alike, even with other words. Its code is in workshop/tools/vectors.
# Two databases: group.sqlite holds your day; example-team.sqlite the example team, given.
# Once your day is kept, ask, eval and sql read it; before that, or with --example, the
# example team. Indexing a folder again replaces only what came from it.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
example_db="$here/example-team.sqlite"
group_db="$here/group.sqlite"
piece=800 # bytes of one memory: small enough to be about one thing

command -v sqlite3 > /dev/null 2>&1 || { printf 'sqlite3 not found: install SQLite 3 with FTS5\n' >&2; exit 1; }

# sql_quote: stdin as an SQL string literal, its quotes doubled.
sql_quote() { sed "s/'/''/g; 1s/^/'/; \$s/\$/'/"; }

schema() {
  cat << 'SQL'
CREATE TABLE IF NOT EXISTS sessions (session_id TEXT PRIMARY KEY, kind TEXT, title TEXT,
  started_at TEXT, ended_at TEXT);
CREATE TABLE IF NOT EXISTS exchanges (id INTEGER PRIMARY KEY, session_id TEXT,
  exchange_number INTEGER, human_text TEXT, agent_text TEXT, human_timestamp TEXT,
  agent_timestamp TEXT, model TEXT, tokens_in INTEGER, tokens_out INTEGER, cost REAL);
CREATE TABLE IF NOT EXISTS tool_uses (id INTEGER PRIMARY KEY, session_id TEXT,
  exchange_number INTEGER, tool_name TEXT, tool_params_summary TEXT, had_error INTEGER,
  error_message TEXT);
CREATE TABLE IF NOT EXISTS thinking_blocks (id INTEGER PRIMARY KEY, session_id TEXT,
  exchange_number INTEGER, full_text TEXT);
CREATE TABLE IF NOT EXISTS memories (id INTEGER PRIMARY KEY, source TEXT, layer TEXT,
  who TEXT, content TEXT);
CREATE VIRTUAL TABLE IF NOT EXISTS exchanges_fts USING fts5(human_text, agent_text,
  content='exchanges', content_rowid='id');
CREATE VIRTUAL TABLE IF NOT EXISTS thinking_fts USING fts5(full_text,
  content='thinking_blocks', content_rowid='id');
CREATE VIRTUAL TABLE IF NOT EXISTS memories_fts USING fts5(content,
  content='memories', content_rowid='id');
CREATE TRIGGER IF NOT EXISTS exchanges_ai AFTER INSERT ON exchanges BEGIN
  INSERT INTO exchanges_fts(rowid, human_text, agent_text) VALUES (new.id, new.human_text, new.agent_text); END;
CREATE TRIGGER IF NOT EXISTS exchanges_ad AFTER DELETE ON exchanges BEGIN
  INSERT INTO exchanges_fts(exchanges_fts, rowid, human_text, agent_text) VALUES ('delete', old.id, old.human_text, old.agent_text); END;
CREATE TRIGGER IF NOT EXISTS thinking_ai AFTER INSERT ON thinking_blocks BEGIN
  INSERT INTO thinking_fts(rowid, full_text) VALUES (new.id, new.full_text); END;
CREATE TRIGGER IF NOT EXISTS thinking_ad AFTER DELETE ON thinking_blocks BEGIN
  INSERT INTO thinking_fts(thinking_fts, rowid, full_text) VALUES ('delete', old.id, old.full_text); END;
CREATE TRIGGER IF NOT EXISTS memories_ai AFTER INSERT ON memories BEGIN
  INSERT INTO memories_fts(rowid, content) VALUES (new.id, new.content); END;
CREATE TRIGGER IF NOT EXISTS memories_ad AFTER DELETE ON memories BEGIN
  INSERT INTO memories_fts(memories_fts, rowid, content) VALUES ('delete', old.id, old.content); END;
CREATE TABLE IF NOT EXISTS exchange_vectors (id INTEGER PRIMARY KEY, v BLOB);
CREATE TABLE IF NOT EXISTS thinking_vectors (id INTEGER PRIMARY KEY, v BLOB);
CREATE TABLE IF NOT EXISTS memory_vectors (id INTEGER PRIMARY KEY, v BLOB);
SQL
}

# forget <prefix>: the SQL that removes what came from one folder before it is read again.
forget() {
  like=$(printf '%s%%' "$1" | sql_quote)
  cat << SQL
DELETE FROM exchange_vectors WHERE id IN (SELECT id FROM exchanges WHERE session_id LIKE $like);
DELETE FROM thinking_vectors WHERE id IN (SELECT id FROM thinking_blocks WHERE session_id LIKE $like);
DELETE FROM memory_vectors WHERE id IN (SELECT id FROM memories WHERE source LIKE $like);
DELETE FROM exchanges WHERE session_id LIKE $like;
DELETE FROM thinking_blocks WHERE session_id LIKE $like;
DELETE FROM tool_uses WHERE session_id LIKE $like;
DELETE FROM sessions WHERE session_id LIKE $like;
DELETE FROM memories WHERE source LIKE $like;
SQL
}

# layer <source>: what kind of memory a file is.
layer() {
  case $1 in
    */decisions.tsv) echo decision ;;
    notes/*) echo note ;;
    */pr.md) echo 'pull request' ;;
    */journal.jsonl) echo journal ;;
    */report.md) echo report ;;
    */input.json | */output.json) echo step ;;
    */conversations/*) echo conversation ;;
    */handovers/*) echo handover ;;
    */evals/*) echo eval ;;
    */costs/*) echo cost ;;
    *) echo file ;;
  esac
}

# memories <file> <source>: the INSERT statements of a file's memories. Paragraphs (split
# at blank lines; in a .jsonl file each line) go on one memory while it stays under 800
# bytes; a longer one is cut every 800 bytes, never inside a letter (awk counts bytes,
# and € takes three). In the example team's conversations each turn is one memory, with
# who said it, and the conversation's title, with its date, on every turn.
memories() {
  case $1 in */conversations/*.md) speakers=1 ;; *) speakers=0 ;; esac
  case $1 in *.jsonl) each=1 ;; *) each=0 ;; esac
  LC_ALL=C awk -v src="$2" -v lay="$(layer "$2")" -v max="$piece" -v each="$each" -v speakers="$speakers" '
    BEGIN { for (i = 128; i < 192; i++) inside[sprintf("%c", i)] = 1 }
    function q(s) { gsub(/\047/, "\047\047", s); return "\047" s "\047" }
    function cut(s, k) { while (k > 1 && substr(s, k + 1, 1) in inside) k--; return k }
    function out(s) {
      if (s !~ /[^ \t\r\n]/) return
      if (title != "") s = title "\n" s
      printf "INSERT INTO memories (source, layer, who, content) VALUES (%s, %s, %s, %s);\n", q(src), q(lay), q(who), q(s)
    }
    function para(p) {
      if (cur != "" && length(cur) + length(p) > max) { out(cur); cur = "" }
      cur = cur (cur == "" ? "" : "\n\n") p
      while (length(cur) > max * 2) { k = cut(cur, max); out(substr(cur, 1, k)); cur = substr(cur, k + 1) }
    }
    speakers && title == "" && /^# / { title = $0; next }
    speakers && /^[A-Z][A-Za-z]*: / {
      s = substr($0, 1, index($0, ":") - 1)
      if (s != who) { if (p != "") para(p); p = ""; out(cur); cur = ""; who = s }
    }
    /^[ \t\r]*$/ { if (p != "") para(p); p = ""; next }
    each { para($0); next }
    { p = p (p == "" ? "" : "\n") $0 }
    END { if (p != "") para(p); out(cur) }' "$1"
}

# step_title <source>: "run 001-percent-off, step 4 review, round 2" from its path.
step_title() {
  printf '%s\n' "$1" | awk -F/ '{
    run = $2; s = $3; r = ""
    if (match(s, /-r[0-9]+$/)) { r = ", round " substr(s, RSTART + 2); s = substr(s, 1, RSTART - 1) }
    sub(/^step-/, "step ", s); sub(/-/, " ", s)
    print "run " run ", " s r }'
}

# step_kind <source>: who the agent of a run step was.
step_kind() { case $1 in *-review*) echo reviewer ;; *-work*) echo worker ;; *) echo agent ;; esac; }

vectors_program() {
  case $(uname -s) in
    Darwin) vp_os=darwin ;;
    Linux) vp_os=linux ;;
    MINGW* | MSYS* | CYGWIN*) vp_os=windows ;;
    *) return 0 ;;
  esac
  case $(uname -m) in
    arm64 | aarch64) vp_arch=arm64 ;;
    x86_64 | amd64) vp_arch=amd64 ;;
    *) return 0 ;;
  esac
  vp="$here/bin/vectors-$vp_os-$vp_arch"
  if [ "$vp_os" = windows ]; then vp="$vp.exe"; fi
  [ -f "$vp" ] && [ -f "$here/minilm.bin" ] || return 0
  [ -x "$vp" ] || chmod +x "$vp" 2> /dev/null || true
  printf '%s\n' "$vp"
}

# conversation <file> <session_id> <kind> <title>: the SQL of one Copilot conversation.
conversation() {
  vp=$(vectors_program)
  if [ -z "$vp" ]; then
    printf 'cannot read %s: no program for this system (%s %s)\n' "$2" "$(uname -s)" "$(uname -m)" >&2
    return 0
  fi
  "$vp" events "$2" "$3" "$4" < "$1"
}

# chief_sessions: this repository's Copilot sessions, the chief's conversations with you.
chief_sessions() {
  root=$(git -C "$here" rev-parse --show-toplevel 2> /dev/null || true)
  [ -n "$root" ] || return 0
  for f in "$HOME"/.copilot/session-state/*/workspace.yaml; do
    [ -f "$f" ] || continue
    grep -qx "cwd: $root" "$f" || continue
    d=$(dirname "$f")
    [ -f "$d/events.jsonl" ] && printf '%s\n' "$d"
  done
}

index_all() {
  db=$group_db
  for folder in "$@"; do
    if [ "$folder" != chief ] && [ "$(basename "$folder")" = example-team ]; then db=$example_db; fi
  done
  {
    schema
    printf 'BEGIN;\n'
    for folder in "$@"; do
      if [ "$folder" = chief ]; then
        forget chief/
        chief_sessions | while read -r d; do
          id=$(basename "$d")
          conversation "$d/events.jsonl" "chief/$id" chief "your conversation with the chief"
        done
        continue
      fi
      [ -d "$folder" ] || { printf 'no folder: %s\n' "$folder" >&2; continue; }
      full=$(cd "$folder" && pwd)
      name=$(basename "$full")
      forget "$name/"
      # What a run leaves that is not its story: the clone it worked on; and Copilot's
      # exports of a conversation that copilot.jsonl already holds.
      (cd "$full" && find . \( -name workspace -o -name node_modules -o -name .git \) -prune -o -type f \
        \( -name '*.md' -o -name '*.txt' -o -name '*.log' -o -name '*.tsv' -o -name '*.json' \
        -o -name '*.jsonl' -o -name '*.yaml' -o -name '*.yml' \) -print) | sort | while read -r f; do
        src="$name/${f#./}"
        case $src in
          */conversation.md | */agent.log) ;;
          */copilot.jsonl) conversation "$full/${f#./}" "$src" "$(step_kind "$src")" "$(step_title "$src")" ;;
          *) memories "$full/${f#./}" "$src" ;;
        esac
      done
    done
    printf 'COMMIT;\n'
  } > "$here/.index.sql"
  sqlite3 "$db" < "$here/.index.sql"
  rm -f "$here/.index.sql"
  embed_missing "$db"
  summary "$db"
}

# summary <db>: what is kept, in plain words.
summary() {
  sqlite3 -readonly -batch -noheader -separator ' ' "$1" "
    SELECT (SELECT count(DISTINCT substr(session_id, 1, instr(substr(session_id, 6), '/') + 5))
              FROM sessions WHERE session_id LIKE 'runs/%'),
           (SELECT count(*) FROM sessions WHERE kind != 'chief'),
           (SELECT count(*) FROM sessions WHERE kind = 'chief'),
           (SELECT count(*) FROM tool_uses),
           (SELECT count(DISTINCT source) FROM memories);" | {
    read -r runs agents chiefs tools files
    if [ "$1" = "$example_db" ]; then
      printf 'The example team is kept: %s of its files.\n' "$files"
    else
      printf 'Your day is kept: %s runs, with %s agent conversations and the %s tools they used; %s conversations with your chief; %s files of reports, notes and decisions.\n' \
        "$runs" "$agents" "$tools" "$chiefs" "$files"
    fi
  }
}

# embed_missing <db>: the vector of every text that has none yet.
embed_missing() {
  vp=$(vectors_program)
  [ -n "$vp" ] || { printf 'by meaning: no program for this system; ask finds by words only\n'; return 0; }
  for kind in exchange thinking memory; do
    case $kind in
      exchange) q="SELECT id, human_text || char(10) || agent_text AS text FROM exchanges" ;;
      thinking) q="SELECT id, full_text AS text FROM thinking_blocks" ;;
      memory) q="SELECT id, content AS text FROM memories" ;;
    esac
    sqlite3 -json "$1" "$q WHERE id NOT IN (SELECT id FROM ${kind}_vectors);" > "$here/.embed.json"
    "$vp" embed "$here/minilm.bin" "${kind}_vectors" < "$here/.embed.json" > "$here/.vectors.sql"
    sqlite3 "$1" < "$here/.vectors.sql"
    rm -f "$here/.embed.json" "$here/.vectors.sql"
  done
}

# indexed <db>: true when the db keeps something.
indexed() { [ -f "$1" ] && [ "$(sqlite3 -readonly "$1" "SELECT count(*) FROM sqlite_master WHERE name = 'memories';")" = 1 ]; }

example=no
which_db() {
  if [ "$example" = no ] && indexed "$group_db"; then printf '%s\n' "$group_db"; else printf '%s\n' "$example_db"; fi
}

# The rows found, one per line: "kind<TAB>id<TAB>score".
# by_words <db> <question>: the best 3 by words, across what was said, thought and written.
by_words() {
  words=$(printf '%s\n' "$2" | awk '
    BEGIN {
      n = split("a an and are as at be but by can did do does for from had has have how i in is it its " \
        "me my no not of on or our so t that the their them there they this to was we were what when where which " \
        "who why will with you your", s, " ")
      for (i = 1; i <= n; i++) stop[s[i]] = 1
    }
    { $0 = tolower($0); gsub(/[^[:alnum:]]+/, " ")
      for (i = 1; i <= NF; i++) if (!($i in stop)) printf "%s\"%s\"", (out++ ? " " : ""), $i }')
  [ -n "$words" ] || return 0
  m=$(printf '%s' "$words" | sql_quote)
  sqlite3 -readonly -batch -noheader -separator '	' "$1" "
    SELECT kind, id, score FROM (
      SELECT 'exchange' AS kind, rowid AS id, bm25(exchanges_fts) AS score FROM exchanges_fts WHERE exchanges_fts MATCH $m
      UNION ALL SELECT 'thinking', rowid, bm25(thinking_fts) FROM thinking_fts WHERE thinking_fts MATCH $m
      UNION ALL SELECT 'memory', rowid, bm25(memories_fts) FROM memories_fts WHERE memories_fts MATCH $m)
    ORDER BY score LIMIT 3;"
}

# by_meaning <db> <question>: the 3 closest in meaning, across the same three.
by_meaning() {
  vp=$(vectors_program)
  [ -n "$vp" ] || return 0
  for kind in exchange thinking memory; do
    sqlite3 -readonly -json "$1" "SELECT id, hex(v) AS v FROM ${kind}_vectors;" > "$here/.near.json"
    "$vp" near "$here/minilm.bin" 3 "$2" < "$here/.near.json" | awk -v k="$kind" 'NF == 2 { print k "\t" $1 "\t" $2 }'
  done | sort -t '	' -k3,3 -rn | head -n 3
  rm -f "$here/.near.json"
}

# show <db> <width>: each "kind<TAB>id<TAB>score" line read in plain words: where it comes
# from, when, and who said what.
show() {
  n=0
  w=$2
  # clip <sql expression>: the text on one line, cut at the width.
  clip() {
    t="trim(replace(replace(replace($1, char(13), ' '), char(10), ' '), char(9), ' '))"
    printf "CASE WHEN length(%s) > %s THEN substr(%s, 1, %s) || '…' ELSE %s END" "$t" "$w" "$t" "$w" "$t"
  }
  human="CASE s.kind WHEN 'chief' THEN 'You said' ELSE 'The graph asked' END"
  agent="CASE s.kind WHEN 'chief' THEN 'The chief' WHEN 'worker' THEN 'The worker' WHEN 'reviewer' THEN 'The reviewer' ELSE 'The agent' END"
  while IFS='	' read -r kind id score; do
    [ -n "$id" ] || continue
    n=$((n + 1))
    case $kind in
      exchange) q="SELECT '  $n. ' || s.title || coalesce(', ' || nullif(e.human_timestamp, ''), '')
          || CASE WHEN e.human_text != '' THEN char(10) || '     ' || $human || ': ' || $(clip e.human_text) ELSE '' END
          || CASE WHEN e.agent_text != '' THEN char(10) || '     ' || $agent || ' answered: ' || $(clip e.agent_text) ELSE '' END
          FROM exchanges e JOIN sessions s USING (session_id) WHERE e.id = $id;" ;;
      thinking) q="SELECT '  $n. ' || s.title || coalesce(', ' || nullif(e.human_timestamp, ''), '')
          || char(10) || '     ' || $agent || ' thought: ' || $(clip t.full_text)
          FROM thinking_blocks t JOIN sessions s USING (session_id)
          LEFT JOIN exchanges e ON e.session_id = t.session_id AND e.exchange_number = t.exchange_number
          WHERE t.id = $id;" ;;
      memory) q="SELECT '  $n. ' || CASE m.layer WHEN 'decision' THEN 'a decision of the day'
            WHEN 'note' THEN 'the chief''s notes' ELSE 'the ' || m.layer END || ', ' || m.source
          || char(10) || '     ' || coalesce(nullif(m.who, '') || ' said: ', '') || $(clip m.content)
          FROM memories m WHERE m.id = $id;" ;;
    esac
    sqlite3 -readonly -batch -noheader "$1" "$q"
  done
}

ask() {
  db=$(which_db)
  if [ "$db" = "$group_db" ]; then
    printf 'YOUR DAY\n'
  else
    if [ "$example" = no ]; then printf 'Your day is not kept yet: sh memory/memory.sh index graph/runs notes chief\n\n'; fi
    printf 'THE EXAMPLE TEAM, THE RESCUE\n'
  fi
  printf '\nFound with your words:\n'
  found=$(by_words "$db" "$1")
  if [ -z "$found" ]; then printf '  nothing has all your words\n'; else printf '%s\n' "$found" | show "$db" 220; fi
  printf '\nFound by meaning, the same idea in other words:\n'
  close=$(by_meaning "$db" "$1")
  if [ -z "$close" ]; then printf '  nothing yet: no program for this system\n'; else printf '%s\n' "$close" | show "$db" 220; fi
  printf '\nThe tools the agents used: sh memory/memory.sh tables\n'
}

tables() {
  cat << 'TXT'
What is kept, as La Roca keeps an agent corpus:
  sessions         one conversation: kind (chief, worker, reviewer), title, started_at, ended_at
  exchanges        one turn: session_id, exchange_number, human_text, agent_text,
                   human_timestamp, agent_timestamp, model, tokens_in, tokens_out, cost
  tool_uses        one tool call: session_id, exchange_number, tool_name,
                   tool_params_summary (the command or the file), had_error, error_message
  thinking_blocks  what the agent thought: session_id, exchange_number, full_text
  memories         what was written down: source, layer (report, pull request, journal,
                   note, decision), who, content

Questions SQL answers (sh memory/memory.sh sql "<SELECT>"):
  Which tools were denied, and where?
    SELECT s.title, t.tool_params_summary, t.error_message FROM tool_uses t
      JOIN sessions s USING (session_id) WHERE t.had_error ORDER BY s.title;
  Which commands did the agents try that wrote to /tmp?
    SELECT s.title, t.tool_params_summary, t.had_error FROM tool_uses t
      JOIN sessions s USING (session_id) WHERE t.tool_params_summary LIKE '%/tmp%';
  What did each run cost, and how long did it take?
    SELECT substr(session_id, 6, instr(substr(session_id, 6), '/') - 1) AS run, sum(tokens_in) AS tokens_in,
      sum(cost) AS cost, min(human_timestamp) AS started, max(agent_timestamp) AS ended
      FROM exchanges WHERE session_id LIKE 'runs/%' GROUP BY run;
  What did we tell the chief, in order?
    SELECT human_timestamp, human_text FROM exchanges WHERE session_id LIKE 'chief/%'
      ORDER BY human_timestamp;
TXT
}

# model <prompt>: the model's answer. Copilot CLI answers with no tools, from an empty folder,
# so the only memory it gets is what we pass.
model() {
  command -v copilot > /dev/null 2>&1 || { printf 'copilot not found: install the GitHub Copilot CLI\n' >&2; exit 1; }
  empty="$here/.empty"
  mkdir -p "$empty"
  copilot -p "$1" -s --no-custom-instructions --disable-builtin-mcps --available-tools=none \
    --disallow-temp-dir -C "$empty" 2>&1 || true
}

# evaluate <question>: the same question to the model twice: alone, and with what ask finds.
evaluate() {
  db=$(which_db)
  notes=$( { by_meaning "$db" "$1"; by_words "$db" "$1"; } | awk -F '\t' 'NF && !seen[$1 FS $2]++' | show "$db" 600)
  rule='Do not use any tools. Answer in at most three sentences. If you do not know, say so.'
  printf 'WITHOUT WHAT WAS KEPT:\n%s\n\n' "$(model "$rule

Question: $1")"
  printf 'WITH WHAT WAS KEPT:\n%s\n\n' "$notes"
  printf 'ANSWER:\n%s\n' "$(model "$rule Answer only from these notes of the team's history, and say which note you used.

$notes

Question: $1")"
}

command=${1:-}
[ $# -eq 0 ] || shift
# One line per command in memory.log: the workshop status reads it to know the group's step.
case $command in
  index | ask | eval | sql) if [ $# -gt 0 ]; then printf '%s\t%s\n' "$command" "$*" >> "$here/memory.log"; fi ;;
esac
case $command in
  ask | eval | sql) if [ "${1:-}" = --example ]; then example=yes; shift; fi ;;
esac
if [ "$command" = index ] && [ $# -gt 0 ]; then
  index_all "$@"
elif [ "$command" = ask ] && [ $# -gt 0 ]; then
  ask "$*"
elif [ "$command" = eval ] && [ $# -gt 0 ]; then
  evaluate "$*"
elif [ "$command" = tables ]; then
  tables
elif [ "$command" = sql ] && [ $# -gt 0 ]; then
  sqlite3 -readonly -box "$(which_db)" "$*"
else
  printf 'Usage: sh memory/memory.sh index <folder>... [chief] | ask [--example] "<question>" | eval [--example] "<question>" | tables | sql [--example] "<SELECT>"\n'
fi
