#!/bin/sh
# Test of graph/run.sh, the path: five steps in order, back to the worker on red, the rounds
# that run out, on_red stop, the journal that state.sh reads, and the run's own copy of the
# repository: made by step 1, worked in by the other steps, two runs at once never meeting;
# and a run that stopped halfway, picked up where it stopped when its ticket is launched again.
# It builds a throwaway group folder with the real node.sh, run.sh, pr.sh, state.sh and lib.sh; the
# agent is graph/tests/fake-agent.sh, the remote is a local bare repository and gh is a
# stand-in that writes what it was asked: no model is called and nothing reaches GitHub.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
graph=$(dirname "$here")
# shellcheck source=/dev/null
. "$graph/lib.sh"
scratch="$graph/runs/test-run-$$"
rm -rf "$scratch"
trap 'rm -rf "$scratch"' EXIT
fail=0
check() { # check <description> <condition...>
  desc=$1
  shift
  if "$@"; then echo "  ok   $desc"; else echo "  FAIL $desc"; fail=1; fi
}

# The throwaway group, a git repository with a bare remote, and gh that only writes a log.
g="$scratch/group"
mkdir -p "$g/graph/tests" "$g/app" "$g/tickets" "$scratch/bin" \
  "$g/.github/skills/worker" "$g/.github/skills/reviewer"
cp "$graph/node.sh" "$graph/run.sh" "$graph/pr.sh" "$graph/state.sh" "$graph/lib.sh" "$g/graph/"
cp "$here/fake-agent.sh" "$g/graph/tests/"
printf 'How a worker works here.\n' > "$g/.github/skills/worker/SKILL.md"
printf 'What a reviewer may block here.\n' > "$g/.github/skills/reviewer/SKILL.md"
printf 'the page\n' > "$g/app/page.txt"
for t in fix never taken resume early alive; do printf '## GOAL\n\nThe fake agent does %s.\n' "$t" > "$g/tickets/$t.md"; done
printf 'graph/runs/\n' > "$g/.gitignore"
printf '#!/bin/sh\nprintf "gh %%s\\n" "$*" >> "%s/gh.log"\necho https://example.test/pull/1\n' "$scratch" > "$scratch/bin/gh"
chmod +x "$scratch/bin/gh"
# stop-run <run>: kills the run.sh that drives that run, as a closed terminal would.
{
  printf '#!/bin/sh\n'
  printf 'kill -9 "$(grep -o %s "%s/graph/runs/$1/journal.jsonl" | head -n 1 | cut -d: -f2)"\n' "'\"pid\":[0-9]*'" "$g"
} > "$scratch/bin/stop-run"
chmod +x "$scratch/bin/stop-run"
git init -q --bare "$scratch/origin.git"
git -C "$g" init -q
git -C "$g" config user.name test
git -C "$g" config user.email test@example.com
git -C "$g" remote add origin "$scratch/origin.git"

# path <rounds of step 3> <run of step 1> [run of step 3]: the five steps of
# graph/path.jsonl, with the fake agent, and step 3 green only when app/fixed exists.
path() {
  fake='"agent":"graph/tests/fake-agent.sh","limit":10'
  {
    printf '{"step":1,"name":"prepare","kind":"commands","dir":".","run":"%s","on_red":"stop"}\n' "$2"
    printf '{"step":2,"name":"work","kind":"agent","dir":"app","skill":"worker",%s,"on_red":"stop"}\n' "$fake"
    printf '{"step":3,"name":"check","kind":"commands","dir":"app","run":"%s","on_red":2,"rounds":%s}\n' "${3:-test -f app/fixed}" "$1"
    printf '{"step":4,"name":"review","kind":"agent","dir":"app","skill":"reviewer",%s,"on_red":2,"rounds":2}\n' "$fake"
    printf '{"step":5,"name":"deliver","kind":"commands","dir":"app","run":"git add -A app && git commit -qm <ticket> && git push -u origin HEAD && sh graph/pr.sh <ticket> <run>","on_red":"stop"}\n'
  } > "$g/graph/path.jsonl"
  git -C "$g" add -A
  git -C "$g" commit -q -m "path" > /dev/null 2>&1 || true
}
prepare='git worktree add <workspace> -b <run>'
# run <name> <ticket>: runs the path from the group folder; its exit code goes to
# <name>.code and what it printed to <name>.out.
run() {
  status=0
  (cd "$g" && PATH="$scratch/bin:$PATH" sh graph/run.sh "tickets/$2.md") > "$scratch/$1.out" 2>&1 < /dev/null || status=$?
  echo "$status" > "$scratch/$1.code"
}
code() { cat "$scratch/$1.code"; }
# wait_for <file>: a killed run leaves its last node finishing on its own; wait for it.
wait_for() {
  w=0
  while [ ! -f "$1" ] && [ "$w" -lt 100 ]; do
    sleep 0.1
    w=$((w + 1))
  done
}
said() { grep -qsF -- "$2" "$1"; }
# visits <run>: the steps in the order they started, as "1 2 3 ...".
visits() { grep -o '"event":"step_started","step":[0-9]*' "$g/graph/runs/$1/journal.jsonl" | sed 's/.*://' | tr '\n' ' '; }
# on_remote <branch> <path>: the file is on that branch of the remote.
on_remote() { git --git-dir="$scratch/origin.git" cat-file -e "$1:$2" 2> /dev/null; }

echo 'scenario: five steps, back to the worker once, then green, in the run'"'"'s own copy'
path 2 "$prepare"
run fix fix
r="$g/graph/runs/fix"
check 'the run exits 0 and says green' sh -c "[ $(code fix) -eq 0 ] && grep -q 'run graph/runs/fix: green' '$scratch/fix.out'"
check 'steps 1, 2, 3 red, back to 2, 3 green, 4, 5' [ "$(visits fix)" = '1 2 3 2 3 4 5 ' ]
check 'the journal has the back event, round 1' said "$r/journal.jsonl" '"event":"back","from":3,"to":2,"round":1'
check 'every journal line is JSON' json_valid "$r/journal.jsonl"
check 'it starts with run_created and ends with run_finished green' \
  sh -c "head -n 1 '$r/journal.jsonl' | grep -q '\"run_created\"' && tail -n 1 '$r/journal.jsonl' | grep -q '\"event\":\"run_finished\",\"status\":\"green\"'"
check 'the red visit of step 3 is kept next to the second one' test -f "$r/step-3-check/output.json" -a -f "$r/step-3-check-r2/output.json"
check 'input.json of step 2 has the ticket, and no last on the first visit' \
  said "$r/step-2-work/input.json" '"ticket":"tickets/fix.md","last":""}'
check 'the second visit of step 2 has the red step as last, a full path' said "$r/step-2-work-r2/input.json" "\"last\":\"$g/graph/runs/fix/step-3-check\""
check 'a commands step gets no ticket' sh -c "! grep -q '\"ticket\"' '$r/step-3-check/input.json'"
check '<ticket> is replaced by the ticket name' said "$r/step-5-deliver/input.json" 'git commit -qm fix &&'
check '<workspace> and <run> are replaced in step 1' said "$r/step-1-prepare/input.json" '"run":"git worktree add graph/runs/fix/workspace -b fix"'
check 'step 5 pushed the branch of the run to the remote' git --git-dir="$scratch/origin.git" show-ref --verify -q refs/heads/fix
check 'the work is on that branch: app/fixed' on_remote fix app/fixed
check 'the group folder'"'"'s app/ did not change' test ! -e "$g/app/fixed"
check 'the copy is gone after green, the run folder stays' test ! -e "$r/workspace" -a -f "$r/journal.jsonl"
check 'the journal says what became of the copy' said "$r/journal.jsonl" '"workspace":"removed"'
check 'step 5 opened the pull request with a title and a text file' said "$scratch/gh.log" 'gh pr create --title fix --body-file'
check 'the text of the pull request: the ticket'"'"'s goal' said "$r/pr.md" 'The fake agent does fix.'
check 'the text of the pull request: what the worker changed, its last visit' said "$r/pr.md" '**Changed** (step-2-work-r2)'
check 'the text of the pull request: the reviewer, and the rounds' sh -c "grep -q '^\*\*Reviewer\*\* (step-4-review)' '$r/pr.md' && grep -q 'went back to the worker once' '$r/pr.md'"
check 'the link of the pull request is in pr.url' said "$r/pr.url" 'https://example.test/pull/1'
check 'and in the journal, as the event pull_request' said "$r/journal.jsonl" '"event":"pull_request","url":"https://example.test/pull/1"'
check 'the terminal: one line when each step starts, with the round' said "$scratch/fix.out" '── step 3 of 5: check (commands, round 2) ──'
check 'the terminal: the node answer with its mark' said "$scratch/fix.out" '✗ red: commands failed'
check 'the terminal: the back line' said "$scratch/fix.out" '↩ back to step 2, round 1 of 2'
check 'the terminal: the run ends with its mark and the link' sh -c "grep -qF '✓ run graph/runs/fix: green' '$scratch/fix.out' && grep -qF 'pull request: https://example.test/pull/1' '$scratch/fix.out'"
status=0
(cd "$g" && sh graph/state.sh graph/runs/fix) > "$scratch/state.out" 2>&1 || status=$?
check 'state.sh: exit 0, finished green' sh -c "[ $status -eq 0 ] && grep -q 'finished green' '$scratch/state.out'"
check 'state.sh: one line per step visit' [ "$(grep -c '^  step ' "$scratch/state.out")" -eq 7 ]
check 'state.sh shows the pull request' said "$scratch/state.out" 'pull request: https://example.test/pull/1'
check 'state.sh: the five steps' sh -c "for s in '1 prepare' '2 work' '3 check' '4 review' '5 deliver'; do grep -q \"^  step \$s: green\" '$scratch/state.out' || exit 1; done"
check 'state.sh: the red step and the round used' sh -c "grep -q '^  step 3 check: red' '$scratch/state.out' && grep -q 'rounds used: step 3: 1' '$scratch/state.out'"

echo 'scenario: the same ticket twice at once: two runs, two copies, two branches'
run twin-a fix &
run twin-b fix &
wait
check 'both runs exit 0' sh -c "[ $(code twin-a) -eq 0 ] && [ $(code twin-b) -eq 0 ]"
check 'two new run folders, fix-2 and fix-3' test -f "$g/graph/runs/fix-2/journal.jsonl" -a -f "$g/graph/runs/fix-3/journal.jsonl"
check 'each went through the five steps' [ "$(visits fix-2)$(visits fix-3)" = '1 2 3 2 3 4 5 1 2 3 2 3 4 5 ' ]
check 'the branch fix-2 on the remote has the work' on_remote fix-2 app/fixed
check 'the branch fix-3 on the remote has the work' on_remote fix-3 app/fixed
check 'the group folder'"'"'s app/ still did not change' test ! -e "$g/app/fixed"

echo 'scenario: the rounds run out, a person decides, and the copy is kept'
path 1 "$prepare"
run never never
r="$g/graph/runs/never"
check 'the run exits 1' [ "$(code never)" -eq 1 ]
check 'steps 1, 2, 3 red, back to 2, 3 red, end' [ "$(visits never)" = '1 2 3 2 3 ' ]
check 'it ends red: a person decides' said "$r/journal.jsonl" '"why":"step 3 red after 1 rounds: a person decides"'
check 'one back event' [ "$(grep -c '"event":"back"' "$r/journal.jsonl")" -eq 1 ]
check 'the copy is kept for the person' test -d "$r/workspace"
check 'the journal says where' said "$r/journal.jsonl" '"workspace":"kept at graph/runs/never/workspace"'
status=0
(cd "$g" && sh graph/state.sh graph/runs/never) > "$scratch/state-never.out" 2>&1 || status=$?
check 'state.sh: exit 1, finished red' sh -c "[ $status -eq 1 ] && grep -q 'finished red: step 3 red after 1 rounds' '$scratch/state-never.out'"

echo 'scenario: a branch that already exists: step 1 red, nothing made'
path 2 "$prepare"
git -C "$g" branch taken
run taken taken
r="$g/graph/runs/taken"
check 'the run exits 1' [ "$(code taken)" -eq 1 ]
check 'only step 1 ran' [ "$(visits taken)" = '1 ' ]
check 'it ends red, naming step 1' said "$r/journal.jsonl" '"status":"red","why":"step 1 prepare red: commands failed'
check 'no copy was made' test ! -e "$r/workspace"

echo 'scenario: uncommitted changes in the group folder: refused before any run folder'
printf 'not committed\n' > "$g/app/draft.txt"
run dirty fix
check 'the run exits 1 and says commit first' sh -c "[ $(code dirty) -eq 1 ] && grep -q 'commit first' '$scratch/dirty.out'"
check 'it names the file' said "$scratch/dirty.out" 'app/draft.txt'
check 'no run folder was made' test ! -e "$g/graph/runs/fix-4"
rm "$g/app/draft.txt"

echo 'scenario: on_red stop on step 1 ends the run at once'
path 2 'echo no copy today; exit 1'
run stop never
r="$g/graph/runs/never-2"
check 'the same ticket again gets a new folder, never-2' test -f "$r/journal.jsonl"
check 'the run exits 1' [ "$(code stop)" -eq 1 ]
check 'only step 1 ran' [ "$(visits never-2)" = '1 ' ]
check 'it ends red, naming step 1' said "$r/journal.jsonl" '"status":"red","why":"step 1 prepare red: commands failed'

echo 'scenario: a green step 1 that leaves no copy is red'
path 2 'true'
run nocopy never
r="$g/graph/runs/never-3"
check 'the run exits 1' [ "$(code nocopy)" -eq 1 ]
check 'only step 1 ran' [ "$(visits never-3)" = '1 ' ]
check 'it says step 1 left no copy' said "$r/journal.jsonl" 'step 1 left no copy at graph/runs/never-3/workspace'

echo 'scenario: a run stopped halfway is picked up where it stopped'
path 2 "$prepare" 'stop-run <run>'
run cut resume
r="$g/graph/runs/resume"
wait_for "$r/step-3-check/output.json"
check 'the run was cut in step 3: no run_finished' sh -c "! grep -q run_finished '$r/journal.jsonl'"
path 2 "$prepare" 'test -f app/fake-resume.txt'
run again resume
check 'launched again, it exits 0 and says green' sh -c "[ $(code again) -eq 0 ] && grep -q 'run graph/runs/resume: green' '$scratch/again.out'"
check 'it says where it picked up' said "$scratch/again.out" 'stopped halfway: picked up at step 3'
check 'no new run folder' test ! -e "$g/graph/runs/resume-2"
check 'the journal has run_resumed at step 3' said "$r/journal.jsonl" '"event":"run_resumed","step":3,'
check 'steps 1 and 2 are not done again: 1 2 3, then 3 4 5' [ "$(visits resume)" = '1 2 3 3 4 5 ' ]
check 'step 3 again in a fresh folder, the cut one kept' test -f "$r/step-3-check/output.json" -a -f "$r/step-3-check-r2/output.json"
check 'the work of step 2 is on the branch' on_remote resume app/fake-resume.txt
check 'every journal line is JSON' json_valid "$r/journal.jsonl"
(cd "$g" && sh graph/state.sh graph/runs/resume) > "$scratch/state-resume.out" 2>&1 || true
check 'state.sh shows where it was picked up' said "$scratch/state-resume.out" 'stopped halfway, picked up at step 3'

echo 'scenario: stopped once step 1 made the copy: step 1 is not done again'
path 2 "$prepare && stop-run <run>" 'true'
run cut-early early
r="$g/graph/runs/early"
wait_for "$r/step-1-prepare/output.json"
path 2 "$prepare" 'true'
run again-early early
check 'launched again, it exits 0' [ "$(code again-early)" -eq 0 ]
check 'it picks up at step 2, the copy is there' said "$r/journal.jsonl" '"event":"run_resumed","step":2,'
check 'step 1 ran once: 1, then 2 3 4 5' [ "$(visits early)" = '1 2 3 4 5 ' ]
check 'the branch early is on the remote' git --git-dir="$scratch/origin.git" show-ref --verify -q refs/heads/early

echo 'scenario: a run whose process is still alive is not picked up'
mkdir -p "$g/graph/runs/alive"
printf '{"seq":1,"ts":"t","event":"run_created","ticket":"tickets/alive.md","pid":%s}\n' "$$" > "$g/graph/runs/alive/journal.jsonl"
run alive alive
check 'the same ticket gets a new run, alive-2' test -f "$g/graph/runs/alive-2/journal.jsonl"
check 'the live run is untouched: one line in its journal' [ "$(grep -c . "$g/graph/runs/alive/journal.jsonl")" -eq 1 ]

exit $fail
