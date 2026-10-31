#!/bin/sh
# Hands one ticket to a worker, outside a run: sh graph/worker.sh tickets/<ticket>.md
# Run it from the group folder, inside the terminal panel of the Copilot app, so the group
# watches the worker work: graph/narrate.sh shows what it says and what it does, each line
# with the time. The same lines are kept in graph/runs/worker-<ticket>.log; every event
# Copilot wrote, in graph/runs/worker-<ticket>-1.jsonl and -2.jsonl.
# "Test first" is not a sentence in the brief: it is the loop. The worker gets two jobs
# with a check between them that cannot be talked out of (Javi, 31 October: three workers
# in a row wrote the code before the test):
#   1. write only the test named in VERIFY, under graph/tests/; nothing else may change,
#      and the test must be red (a test that passes with no code proves nothing);
#   2. write the code until that test passes; the test must not change.
# The chief never launches a worker any other way: the workshop's hook blocks it.
set -eu
ticket=${1:-}
if [ -z "$ticket" ] || [ ! -f "$ticket" ]; then
  printf 'no ticket: %s (run it from the group folder: sh graph/worker.sh tickets/<ticket>.md)\n' "$ticket" >&2
  exit 2
fi
name=$(basename "$ticket" .md)
log="graph/runs/worker-$name.log"
mkdir -p graph/runs
# The test of VERIFY: the first graph/tests/test-*.sh the section names.
test=$(sed -n '/^## VERIFY/,/^## [A-Z]/p' "$ticket" | grep -o 'graph/tests/test-[A-Za-z0-9-]*\.sh' | head -n 1)
if [ -z "$test" ]; then
  printf 'the VERIFY of %s names no graph/tests/test-*.sh: nothing to write first\n' "$ticket" >&2
  exit 2
fi

# Blue for ok and orange for failed, never green and red: a colour-blind person tells blue
# from orange, and the mark and the words say it anyway.
esc=$(printf '\033')
dim="${esc}[2m" bold="${esc}[1m" blue="${esc}[34m" orange="${esc}[38;5;208m" off="${esc}[0m"
ok() { printf '\n%s%s%s  %s%s\342\234\223 %s%s\n\n' "$dim" "$(date +%H:%M:%S)" "$off" "$blue" "$bold" "$1" "$off"; }
no() { printf '\n%s%s%s  %s%s\342\234\227 %s%s\n\n' "$dim" "$(date +%H:%M:%S)" "$off" "$orange" "$bold" "$1" "$off"; }
# changed: what differs from the last commit in the group folder, runs aside, as paths
# from the group folder (git prints them from the root of the repository).
prefix=$(git rev-parse --show-prefix 2> /dev/null || true)
changed() { git status --porcelain -- . ':(exclude)graph/runs' 2> /dev/null | sed "s/^...//; s|^$prefix||" | sort; }

common="You are a worker on the ticket $ticket: implement that ticket only. Its SCOPE and FORBIDDEN are the fence; its ACCEPTANCE and VERIFY say when you are done. Do not read COS.md. Do not run git commands that change state. People who do not program are watching you work in a terminal. They see two things: what you say, and the description of each command. So: give every command a short description in plain words, what it is for, never the command itself. Before each step, say in one plain sentence what you are going to do and why; after a test or a check, say in one sentence what it showed."
# Workers cannot see the chat: the group's standing orders go with every brief.
if [ -f STANDING.md ]; then common="$common
STANDING ORDERS:
$(cat STANDING.md)"; fi
first="Step 1 of 2: write ONLY the test of VERIFY, $test, under graph/tests/. Do not write the code it tests, and change nothing else: the test must fail now, because the code is not there yet. When the test is written, run it once to see it red, then stop and say in two sentences what it checks. $common"
second="Step 2 of 2: the test $test is already written and must not change. Write the code until $test passes. When you finish, say: done or blocked, the files you changed, anything you did that the ticket did not ask for, and the output of VERIFY. $common"

# job <n> <brief>: Copilot on the brief, narrated; its events kept; its exit code returned.
job() {
  jb_code=0
  {
    WORKSHOP_WORKER=1 copilot -p "$2" --allow-all-tools --output-format json ${MODEL:+--model "$MODEL"} 2>&1 || jb_code=$?
    echo "$jb_code" > "graph/runs/worker-$name-$1.exit"
  } | tee "graph/runs/worker-$name-$1.jsonl" | sh graph/narrate.sh
  return "$(cat "graph/runs/worker-$name-$1.exit")"
}

{
  printf 'Worker on %s, started %s. Log: %s\n' "$ticket" "$(date +%H:%M:%S)" "$log"
  printf '%sTwo jobs: first the test, %s, red; then the code until it is green.%s\n\n' "$dim" "$test" "$off"
  changed > "graph/runs/.before-$name"
  code=0
  job 1 "$first" || code=$?
  changed > "graph/runs/.after-$name"
  result=''
  for f in $(comm -13 "graph/runs/.before-$name" "graph/runs/.after-$name"); do
    case $f in graph/tests/*) ;; *) result="job 1 changed $f: only the test may change in job 1" ;; esac
  done
  rm -f "graph/runs/.before-$name" "graph/runs/.after-$name"
  if [ -n "$result" ]; then no "$result"
  elif [ ! -f "$test" ]; then no "job 1 left no $test"
  elif sh "$test" > /dev/null 2>&1; then no "$test passes with no code: it proves nothing"
  else ok "$test is written and red, as it should be"
    stamp=$(cksum < "$test")
    code=0
    job 2 "$second" || code=$?
    if [ "$(cksum < "$test")" != "$stamp" ]; then no "the test changed during job 2"
    elif sh "$test" > /dev/null 2>&1; then ok "$test is green and the test did not change"; result=green
    else no "$test is still red after job 2"
    fi
  fi
  if [ "$result" = green ]; then code=0; else code=1; fi
  printf 'Worker on %s ended %s, exit %s\n' "$ticket" "$(date +%H:%M:%S)" "$code"
  echo "$code" > "graph/runs/worker-$name.exit"
} | tee "$log.ansi"
sed "s/$(printf '\033')\[[0-9;]*m//g" "$log.ansi" >> "$log"
rm -f "$log.ansi"
exit "$(cat "graph/runs/worker-$name.exit")"
