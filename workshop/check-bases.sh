#!/bin/sh
# For the facilitator and the CI: checks every starting point of every domain before the
# workshop. At the start of hour N, what hour N-1 builds must be there and green, and what
# hour N builds must not be there yet.
# Needs Chrome or Edge on the machine (or BROWSER=<path to one>): the app's tests are pages
# that app/check.sh test opens in the browser without a window.
# Usage: sh workshop/check-bases.sh [--openspec]   (--openspec also validates the specs)
set -eu
. "$(dirname "$0")/lib.sh"
scratch="$workshop/.check"
rm -rf "$scratch"
fail=0
check() { # check <description> <condition...>
  desc=$1
  shift
  if "$@"; then echo "  ok   $desc"; else echo "  FAIL $desc"; fail=1; fi
}
# count <folder> <pattern>: the names in a folder that match (grep -E), without hidden ones.
count() {
  if [ -d "$1" ]; then
    # shellcheck disable=SC2010 # the names here are plain: tickets, tests
    ls "$1" | grep -cE "$2" || true
  else
    echo 0
  fi
}
# filled <file> <field>: the section "## <field>" has at least one line that is not blank.
filled() {
  awk -v f="## $2" '$0 == f {on = 1; next} /^## / {on = 0} on && /[^ \t]/ {found = 1} END {exit !found}' "$1"
}
# sections_ok <dir>: every ticket is a full brief: the seven sections, none empty.
sections_ok() {
  [ "$(count "$1/tickets" '^[0-9].*\.md$')" -gt 0 ] || return 1
  for t in "$1"/tickets/[0-9]*.md; do
    for f in GOAL SCOPE CONTEXT ACCEPTANCE VERIFY FORBIDDEN REPORT; do
      filled "$t" "$f" || return 1
    done
  done
}
# green <test>: the test exits 0. Its output is not shown.
green() { sh "$1" > /dev/null 2>&1 < /dev/null; }
# stub <script>: the script is a stub of the hour: it runs and exits 2.
stub() {
  st_code=0
  sh "$1" > /dev/null 2>&1 < /dev/null || st_code=$?
  [ "$st_code" -eq 2 ]
}
# in_app <dir> <check.sh command>: the app's check passes. Its output is not shown.
in_app() { sh "$1/app/check.sh" "$2" > /dev/null 2>&1 < /dev/null; }
finished() { sh "$workshop/status.sh" "$1" > /dev/null 2>&1 < /dev/null; }
unfinished() { ! finished "$1"; }
pending() { grep -c '_pending_' "$1/DOMAIN.md" || true; }
hour_mark() { printf 'hour=%s\n' "$2" > "$1/.hour"; }
standing_ok() { [ -s "$1/STANDING.md" ] && [ "$(wc -l < "$1/notes/decisions.tsv")" -eq 1 ]; }
living_spec_ok() {
  [ -f "$1/openspec/specs/home-page/spec.md" ] && ! grep -rq __PRODUCT__ "$1/openspec/specs" "$1/app"
}
skills_ok() { [ -f "$1/.github/skills/worker/SKILL.md" ] && [ -f "$1/.github/skills/reviewer/SKILL.md" ]; }
memory_ok() { [ -f "$1/memory/memory.sh" ] && [ -f "$1/memory/CASES.md" ] && [ -d "$1/example-team/runs" ]; }
# given <dir>: the graph's pieces every group gets with the template.
given() {
  for f in lib.sh state.sh REPORT.md copilot.sh worker.sh tests/run-all.sh tests/fake-agent.sh runs/.gitkeep; do
    [ -f "$1/graph/$f" ] || return 1
  done
}
none_yet() { [ ! -e "$1/graph/node.sh" ] && [ ! -e "$1/graph/run.sh" ] && [ ! -e "$1/graph/path.jsonl" ] && [ ! -d "$1/graph/nodes" ]; }
unsigned() { grep -q '^Signed: _pending_' "$1"; }
signed() { grep -q '^Signed: ' "$1" && ! unsigned "$1"; }
# path_ok <dir>: graph/path.jsonl has five lines, each one valid JSON with a kind.
path_ok() {
  [ "$(grep -c . "$1/graph/path.jsonl")" -eq 5 ] || return 1
  (
    # shellcheck source=/dev/null
    . "$1/graph/lib.sh"
    json_valid "$1/graph/path.jsonl"
  ) && [ "$(grep -cE '"kind":"(commands|agent)"' "$1/graph/path.jsonl")" -eq 5 ]
}
# smoke_run <dir>: the path of the base, with the fake agent in steps 2 and 4 and true for
# step 5 (no push), on ticket 001, in a throwaway git repository so step 1 makes the run's
# copy. True when the run ends green.
smoke_run() {
  (
    cd "$1"
    sed -e 's|"agent":"[^"]*"|"agent":"graph/tests/fake-agent.sh"|' \
      -e '5s|"run":"[^"]*"|"run":"true"|' graph/path.jsonl > graph/path.smoke
    mv graph/path.smoke graph/path.jsonl
    git init -q && git add -A && git -c user.name=check -c user.email=check@example.invalid commit -qm base
    sh graph/run.sh tickets/001-*.md
  ) > /dev/null 2>&1 < /dev/null
}

# openspec_valid <change dir>: the change has proposal.md, tasks.md and at least one
# specs/*/spec.md; every spec has requirements; every requirement has at least one
# "#### Scenario:", every scenario a WHEN and a THEN line, and no requirement's text is over
# 500 characters. What `openspec validate --strict` checks, in shell.
openspec_valid() {
  [ -f "$1/proposal.md" ] && [ -f "$1/tasks.md" ] || return 1
  found=0
  for spec in "$1"/specs/*/spec.md; do
    [ -f "$spec" ] || continue
    found=1
    awk '
      function close_scenario() { if (inscen && !(when && then)) bad = 1; inscen = 0 }
      function close_requirement() {
        close_scenario()
        if (inreq && (scenarios == 0 || length(text) > 500)) bad = 1
        inreq = 0
      }
      /^### Requirement:/ { close_requirement(); inreq = 1; reqs++; scenarios = 0; text = ""; next }
      /^#### Scenario:/ { close_scenario(); if (!inreq) bad = 1; inscen = 1; scenarios++; when = 0; then = 0; next }
      /^##? / { close_requirement(); next }
      inscen && /\*\*WHEN\*\*/ { when = 1 }
      inscen && /\*\*THEN\*\*/ { then = 1 }
      inreq && !inscen && /[^ \t]/ { text = text (text == "" ? "" : " ") $0 }
      END { close_requirement(); exit (bad || reqs == 0) }' "$spec" || return 1
  done
  [ "$found" -eq 1 ]
}

echo "the chief's guard: the hook that blocks what the chief broke in rehearsals"
check 'the hook is declared in .github/hooks/workshop.json' grep -q 'workshop/hooks/guard.sh' "$workshop/../.github/hooks/workshop.json"
check 'every case of test-guard.sh passes' green "$workshop/hooks/test-guard.sh"
check 'the chief stays with the runs: follow.sh is declared as agentStop' grep -q 'workshop/hooks/follow.sh' "$workshop/../.github/hooks/workshop.json"
check 'every case of test-follow.sh passes' green "$workshop/hooks/test-follow.sh"
echo "the groups' sites: one workflow per group publishes its app when it is merged"
for g in 1 2 3 4; do
  check "group-$g has its workflow, triggered only by its own app" grep -q "group-$g/app/\*\*" "$workshop/../.github/workflows/group-$g.yml"
done
check 'the publish script parses' sh -n "$workshop/../.github/pages/publish.sh"

echo "hour 4's memory: search by meaning, with a small model and its program for the Mac"
mem="$workshop/inputs/hour-4/memory"
# vectors_ready <db>: every exchange, thought and memory has its vector.
vectors_ready() {
  [ "$(sqlite3 "$1" "SELECT (SELECT count(*) FROM exchanges) = (SELECT count(*) FROM exchange_vectors)
    AND (SELECT count(*) FROM thinking_blocks) = (SELECT count(*) FROM thinking_vectors)
    AND (SELECT count(*) FROM memories) = (SELECT count(*) FROM memory_vectors);")" = 1 ]
}
# fresh_memory: a copy of the memory in the scratch folder, with no day of a group kept yet,
# and a home with no Copilot sessions.
fresh_memory() {
  rm -rf "$scratch/memory" "$scratch/runs" "$scratch/home"
  mkdir -p "$scratch/home"
  cp -R "$mem" "$scratch/memory"
}
# memory <args>: the copy's memory.sh, with the scratch home.
memory() { HOME="$scratch/home" sh "$scratch/memory/memory.sh" "$@"; }
# meaning_finds <question> <text>: on a copy of the memory, ask finds the text by meaning in
# the example team, the rescue.
meaning_finds() {
  fresh_memory
  memory ask "$1" | awk '/^Found by meaning/ { on = 1 } on' | grep -q "$2"
}
# copilot_events <file>: a Copilot conversation as Copilot writes it: the human turn, what
# the agent thought, a command it was denied (it wrote outside its folder), a file it read,
# the model's usage, and its answer.
copilot_events() {
  mkdir -p "$(dirname "$1")"
  printf '%s\n' \
    '{"type":"user.message","timestamp":"2026-11-06T10:00:00Z","data":{"content":"Review the ticket."}}' \
    '{"type":"assistant.message","timestamp":"2026-11-06T10:00:05Z","data":{"content":"","reasoningText":"The basket can be empty; is there a test?","toolRequests":[{"toolCallId":"a","name":"bash","arguments":{"command":"sh app/check.sh test > ../../outside.txt"}},{"toolCallId":"b","name":"view","arguments":{"path":"/g/skills/reviewer/SKILL.md"}}]}}' \
    '{"type":"tool.execution_complete","timestamp":"2026-11-06T10:00:06Z","data":{"toolCallId":"a","success":false,"error":{"message":"Permission denied","code":"denied"}}}' \
    '{"type":"tool.execution_complete","timestamp":"2026-11-06T10:00:07Z","data":{"toolCallId":"b","success":true,"result":{"content":"the whole skill file"}}}' \
    '{"type":"session.usage_record","timestamp":"2026-11-06T10:00:08Z","data":{"usage":{"model":"m","inputTokens":100,"outputTokens":10,"cost":1}}}' \
    '{"type":"assistant.message","timestamp":"2026-11-06T10:00:09Z","data":{"content":"I blocked it: no test for an empty basket."}}' \
    > "$1"
}
# like_a_corpus: a run step's Copilot conversation is kept as La Roca keeps one: the human
# turn and the agent's answer, what it thought, each tool with what it asked and whether
# it was denied; what a tool gave back is not kept. The chief's sessions of this
# repository are kept too, and only those.
like_a_corpus() {
  fresh_memory
  copilot_events "$scratch/runs/001-x/step-4-review/copilot.jsonl"
  root=$(git -C "$scratch/memory" rev-parse --show-toplevel)
  copilot_events "$scratch/home/.copilot/session-state/s1/events.jsonl"
  printf 'cwd: %s\n' "$root" > "$scratch/home/.copilot/session-state/s1/workspace.yaml"
  copilot_events "$scratch/home/.copilot/session-state/s2/events.jsonl"
  printf 'cwd: /somewhere/else\n' > "$scratch/home/.copilot/session-state/s2/workspace.yaml"
  memory index "$scratch/runs" chief > /dev/null 2>&1
  lc_db="$scratch/memory/group.sqlite"
  [ "$(sqlite3 "$lc_db" "SELECT group_concat(session_id || ':' || kind, ' ') FROM (SELECT * FROM sessions ORDER BY session_id);")" = \
    'chief/s1:chief runs/001-x/step-4-review/copilot.jsonl:reviewer' ] &&
    [ "$(sqlite3 "$lc_db" "SELECT human_text || '|' || agent_text || '|' || tokens_in FROM exchanges WHERE session_id LIKE 'runs/%';")" = \
      'Review the ticket.|I blocked it: no test for an empty basket.|100' ] &&
    [ "$(sqlite3 "$lc_db" "SELECT count(*) FROM thinking_blocks;")" = 2 ] &&
    [ "$(sqlite3 "$lc_db" "SELECT group_concat(tool_name || ':' || had_error || ':' || error_message, ' ') FROM tool_uses WHERE session_id LIKE 'runs/%';")" = \
      'bash:1:Permission denied view:0:' ] &&
    [ "$(sqlite3 "$lc_db" "SELECT count(*) FROM memories WHERE content LIKE '%the whole skill file%';")" = 0 ] &&
    memory ask "empty basket" | grep -q 'The reviewer answered: I blocked it' &&
    memory ask "empty basket" | grep -q 'You said: Review the ticket.' &&
    memory sql "SELECT tool_params_summary FROM tool_uses WHERE had_error;" | grep -q 'outside.txt'
}
# own_day_first: before the group keeps its day, ask says so and answers from the example
# team, the rescue; after, ask reads only the group's day, and --example the example team.
own_day_first() {
  fresh_memory
  memory ask "who merges" | grep -q 'not kept yet' || return 1
  mkdir -p "$scratch/runs/001-x"
  printf '%s\n' 'A person merges every pull request.' > "$scratch/runs/001-x/pr.md"
  memory index "$scratch/runs" > /dev/null 2>&1
  ! memory ask "who merges" | grep -q 'example-team/' &&
    memory ask "who merges" | grep -q 'runs/001-x/pr.md' &&
    memory ask --example "who merges" | grep -q 'example-team/'
}
check 'the model, minilm.bin' test -s "$mem/minilm.bin"
for v in darwin-arm64 darwin-amd64; do
  check "the vectors program for $v" test -s "$mem/bin/vectors-$v"
done
check "everything the example team said and wrote has its vector" vectors_ready "$mem/example-team.sqlite"
check 'by meaning on this machine: "who is allowed to merge?" finds Ines in the merge conversation' \
  meaning_finds 'who is allowed to merge?' 'Ines said: # Chief and Ines · 12 March'
check "the group's own day first; the example team only before it is kept or with --example" own_day_first
check "a Copilot conversation kept as La Roca keeps one: who said what, thoughts, tools and denials; the chief's sessions of this repository only" like_a_corpus

echo "the chief: Javier's talk of each module, as a skill"
for m in 1 2 3 4; do
  check "skill module-$m" grep -qx "name: module-$m" "$workshop/../.github/skills/module-$m/SKILL.md"
done

echo "the single source: workshop/source/ is what the skills and COS.md say"
check 'the skills and COS.md say what workshop/source says (else: sh workshop/source/render.sh)' sh "$workshop/source/render.sh" --check

while read -r group domain; do
  [ -n "$group" ] || continue

  echo "$domain, start of hour 1: the backlog"
  d1="$scratch/$domain-1/group-x"
  build_base "$d1" "$domain" 1
  check 'three open decisions' [ "$(pending "$d1")" -eq 3 ]
  check 'no tickets yet' [ "$(count "$d1/tickets" '\.md$')" -eq 0 ]
  check 'no node.sh, run.sh or path.jsonl yet: the machine starts in hour 2' none_yet "$d1"
  check 'the given pieces of the graph: lib.sh, state.sh, REPORT.md, copilot.sh, fake-agent.sh' given "$d1"
  check 'standing orders and an empty decision trail' standing_ok "$d1"
  check 'the app test passes' in_app "$d1" test
  check 'living spec of the app exists with the product name' living_spec_ok "$d1"
  check 'status says hour 1 is not finished' unfinished "$d1"

  echo "$domain, start of hour 2: the node"
  d2="$scratch/$domain-2/group-x"
  build_base "$d2" "$domain" 2
  check 'no open decisions' [ "$(pending "$d2")" -eq 0 ]
  check 'product tickets 001 to 003' [ "$(count "$d2/tickets" '^00[1-9]-.*\.md$')" -eq 3 ]
  check 'one ticket for the graph: 000-node.md' [ "$(count "$d2/tickets" '^000-.*\.md$')" -eq 1 -a -f "$d2/tickets/000-node.md" ]
  check '000-node.md is not signed yet: the group signs it' unsigned "$d2/tickets/000-node.md"
  check 'backlog signed off' [ -f "$d2/tickets/backlog-ready.md" ]
  check 'every ticket is a full brief, 000-node.md too' sections_ok "$d2"
  check 'status says hour 1 is finished' finished "$d2"
  check 'the contract: graph/NODE.md' [ -f "$d2/graph/NODE.md" ]
  check 'the given pieces: REPORT.md, copilot.sh, fake-agent.sh' given "$d2"
  check 'node.sh is the stub: it exits 2' stub "$d2/graph/node.sh"
  check 'no test-node.sh yet: the group writes it' [ ! -e "$d2/graph/tests/test-node.sh" ]
  check 'no run.sh and no path.jsonl yet: they are hour 3' [ ! -e "$d2/graph/run.sh" -a ! -e "$d2/graph/path.jsonl" ]
  check 'the app lint passes' in_app "$d2" lint
  hour_mark "$d2" 2
  check 'status says hour 2 is not finished' unfinished "$d2"

  echo "$domain, start of hour 3: the path and the skills"
  d3="$scratch/$domain-3/group-x"
  build_base "$d3" "$domain" 3
  check 'the node is written: test-node.sh is green' green "$d3/graph/tests/test-node.sh"
  check '000-node.md is there, signed' signed "$d3/tickets/000-node.md"
  check 'one ticket for the graph: 000-node.md; run.sh is given, not built' [ "$(count "$d3/tickets" '^000-.*\.md$')" -eq 1 ]
  check 'every ticket is a full brief' sections_ok "$d3"
  check 'the contract: graph/PATH.md, and its drawing' [ -f "$d3/graph/PATH.md" -a -f "$d3/graph/path.png" ]
  check 'run.sh is given and its test is green' green "$d3/graph/tests/test-run.sh"
  check 'pr.sh is given: the deliver line calls it' [ -f "$d3/graph/pr.sh" ]
  check 'no path.jsonl yet: the group writes it' [ ! -e "$d3/graph/path.jsonl" ]
  check 'no skills yet: the chief writes them' [ ! -d "$d3/.github/skills" ]
  check 'the app test passes, and no product ticket is built yet: the first real job is a run of this hour' sh -c "[ ! -e '$d3/app/promotions.js' ] && [ ! -e '$d3/app/basket.js' ] && [ ! -e '$d3/app/stock.js' ] && [ ! -e '$d3/app/loyalty.js' ]"
  check 'the app test passes' in_app "$d3" test
  check 'the app lint passes' in_app "$d3" lint
  check 'the app typecheck passes' in_app "$d3" typecheck
  hour_mark "$d3" 3
  check 'status says hour 3 is not finished' unfinished "$d3"

  echo "$domain, start of hour 4: ask your system"
  d4="$scratch/$domain-4/group-x"
  build_base "$d4" "$domain" 4
  check 'one ticket for the graph: 000-node.md, signed' \
    sh -c "[ $(count "$d4/tickets" '^000-.*\.md$') -eq 1 ] && ! grep -q '^Signed: _pending_' '$d4'/tickets/000-*.md"
  check 'worker and reviewer skills' skills_ok "$d4"
  check 'the reviewer skill ends with a Verdict line' grep -q 'Verdict: block' "$d4/.github/skills/reviewer/SKILL.md"
  check 'path.jsonl has five steps, each a JSON line with a kind' path_ok "$d4"
  check 'test-run.sh is green' green "$d4/graph/tests/test-run.sh"
  check 'the deliver line of the path calls pr.sh' grep -q 'sh graph/pr.sh <ticket> <run>' "$d4/graph/path.jsonl"
  check 'every test of the graph is green' green "$d4/graph/tests/run-all.sh"
  check 'the memory tool, its cases and the example team' memory_ok "$d4"
  check 'a run of ticket 001 with the fake agent ends green' smoke_run "$d4"
  hour_mark "$d4" 3
  check 'status says hour 3 is finished' finished "$d4"
  hour_mark "$d4" 4
  check 'status says hour 4 is not finished' unfinished "$d4"
  if [ "${1:-}" = --openspec ]; then
    for c in "$d3"/openspec/changes/*/; do
      c=$(basename "$c")
      [ "$c" != archive ] || continue
      check "openspec: $c is valid" openspec_valid "$d3/openspec/changes/$c"
    done
  fi
done < "$workshop/groups.txt"

rm -rf "$scratch"
if [ "$fail" -eq 0 ]; then echo 'all starting points are as expected'; fi
exit "$fail"
