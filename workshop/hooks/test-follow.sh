#!/bin/sh
# Tests workshop/hooks/follow.sh, the agentStop hook that keeps the chief with the runs,
# on a throwaway root with journals shaped like run.sh writes them. One "  ok" or "  FAIL"
# line per case. Usage: sh workshop/hooks/test-follow.sh
set -u
here=$(cd "$(dirname "$0")" && pwd)
fail=0
root=$(mktemp -d "$here/.panel/test-follow.XXXXXX")
trap 'rm -rf "$root"' EXIT
runs="$root/group-9/graph/runs"
mkdir -p "$runs/001-old" "$runs/002-going" "$runs/003-new"
export WORKSHOP_ROOT="$root" WORKSHOP_PANEL="$root/panel"

stop() { printf '{"sessionId":"s1","timestamp":1,"cwd":"%s","transcriptPath":"%s","stopReason":"end_turn"}' "$root" "$root/transcript.jsonl" | sh "$here/follow.sh"; }
: > "$root/transcript.jsonl"
check() { # check <description> <condition...>
  d=$1; shift
  if "$@"; then echo "  ok   $d"; else echo "  FAIL $d"; fail=1; fi
}
said() { printf '%s' "$1" | grep -qF -- "$2"; }
not_said() { ! said "$1" "$2"; }

# A run finished before the session: taken note of on the first stop, never announced.
printf '{"seq":1,"event":"run_created","ticket":"tickets/001-old.md","pid":1}\n{"seq":2,"event":"run_finished","status":"green","why":"step 5 green"}\n' > "$runs/001-old/journal.jsonl"
out=$(stop)
check 'first stop of a session: an old finished run is not news' [ -z "$out" ]

# A run going, driven by a live process (this test): the chief is sent back to it.
printf '{"seq":1,"event":"run_created","ticket":"tickets/002-going.md","pid":%s}\n{"seq":2,"event":"step_started","step":2,"name":"work"}\n' "$$" > "$runs/002-going/journal.jsonl"
out=$(stop)
check 'a run still going: block' said "$out" '"decision":"block"'
check 'it names the run and its last event' said "$out" 'group-9/graph/runs/002-going (last event: step_started, step 2)'
check 'it tells the chief to stay until green or red' said "$out" 'Do not end your turn while it goes'

# A run that ended since the last stop, with a pull request: announced once, with the link.
printf '{"seq":1,"event":"run_created","ticket":"tickets/003-new.md","pid":1}\n{"seq":2,"event":"pull_request","url":"https://example.test/pull/7","title":"003"}\n{"seq":3,"event":"run_finished","status":"green","why":"step 5 green"}\n' > "$runs/003-new/journal.jsonl"
printf 'https://example.test/pull/7\n' > "$runs/003-new/pr.url"
out=$(stop)
check 'a run that ended: block' said "$out" '"decision":"block"'
check 'it says the result in the terminal words' said "$out" 'Run group-9/graph/runs/003-new ended green: step 5 green.'
check 'it gives the pull request link' said "$out" 'Pull request: https://example.test/pull/7.'
check 'and still names the run going' said "$out" '002-going'
out=$(stop)
check 'the ended run is not announced twice' not_said "$out" 003-new

# The going run stops (its process gone) with no run_finished: it is not alive, nothing to say.
sed -i '' "s/\"pid\":$$/\"pid\":999999/" "$runs/002-going/journal.jsonl"
out=$(stop)
check 'a run whose process is gone and no new end: the turn ends' [ -z "$out" ]

# A red run: the reason says it is red and that a person decides.
printf '{"seq":3,"event":"run_finished","status":"red","why":"step 4 red after 2 rounds: a person decides","workspace":"kept"}\n' >> "$runs/002-going/journal.jsonl"
out=$(stop)
check 'a red run: its reason' said "$out" 'ended red: step 4 red after 2 rounds: a person decides.'
check 'a red run: no link' not_said "$out" 'Pull request'

# A run the chief already announced in its last message, with its link: not news.
mkdir -p "$runs/005-said"
printf '{"seq":1,"event":"run_created","ticket":"tickets/005-said.md","pid":1}\n{"seq":2,"event":"run_finished","status":"green","why":"step 5 green"}\n' > "$runs/005-said/journal.jsonl"
printf 'https://example.test/pull/8\n' > "$runs/005-said/pr.url"
printf '{"type":"assistant.message","data":{"content":"Run 005-said ended green. Pull request: https://example.test/pull/8"}}\n' > "$root/transcript.jsonl"
out=$(stop)
check 'a run the chief already announced with its link: the turn ends' [ -z "$out" ]
: > "$root/transcript.jsonl"

# A worker never gets this hook.
out=$(WORKSHOP_WORKER=1 stop)
check 'a worker (WORKSHOP_WORKER=1) is left alone' [ -z "$out" ]

# The reason is one JSON string: no quotes or new lines inside it.
printf '{"seq":1,"event":"run_created","ticket":"tickets/004-q.md","pid":1}\n{"seq":2,"event":"run_finished","status":"red","why":"the \\"why\\" with quotes"}\n' > "$runs/004-q.journal"
mkdir -p "$runs/004-q"
mv "$runs/004-q.journal" "$runs/004-q/journal.jsonl"
out=$(stop)
check 'the reason is valid JSON' python3 -c "import json,sys; json.loads(sys.argv[1])" "$out"

exit $fail
