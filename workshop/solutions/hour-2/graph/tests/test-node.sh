#!/bin/sh
# Test of graph/node.sh, the node: the six cases of graph/NODE.md, and the reviewer's
# verdict. It builds a throwaway group folder with the real node.sh and lib.sh, and the
# agent is graph/tests/fake-agent.sh: no model is called.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
graph=$(dirname "$here")
# shellcheck source=/dev/null
. "$graph/lib.sh"
scratch="$graph/runs/test-node-$$"
rm -rf "$scratch"
trap 'rm -rf "$scratch"' EXIT
fail=0
check() { # check <description> <condition...>
  desc=$1
  shift
  if "$@"; then echo "  ok   $desc"; else echo "  FAIL $desc"; fail=1; fi
}

# The throwaway group: app/, tickets/ named after what the fake agent does, a worker
# skill, and git, so the node can see what the agent changed.
g="$scratch/group"
mkdir -p "$g/graph/tests" "$g/app" "$g/tickets" "$g/.github/skills/worker"
cp "$graph/node.sh" "$graph/lib.sh" "$g/graph/"
cp "$here/fake-agent.sh" "$g/graph/tests/"
for t in good fail slow outside no-report bad-report block pass fix; do
  printf '## GOAL\n\nThe fake agent does %s.\n' "$t" > "$g/tickets/$t.md"
done
printf 'How a worker works here.\n' > "$g/.github/skills/worker/SKILL.md"
printf 'the page\n' > "$g/app/page.txt"
printf 'graph/runs/\n' > "$g/.gitignore"
git -C "$g" init -q
git -C "$g" add -A
git -C "$g" -c user.name=t -c user.email=t@t commit -q -m init

# step <name> <input line>: writes graph/runs/t/<name>/input.json in the throwaway group and
# runs the node there; its exit code goes to <name>.code and what it printed to <name>.out.
step() {
  mkdir -p "$g/graph/runs/t/$1"
  printf '%s\n' "$2" > "$g/graph/runs/t/$1/input.json"
  status=0
  (cd "$g" && sh graph/node.sh "graph/runs/t/$1") > "$scratch/$1.out" 2>&1 < /dev/null || status=$?
  echo "$status" > "$scratch/$1.code"
}
code() { cat "$scratch/$1.code"; }
says() { grep -qsF -- "$2" "$g/graph/runs/t/$1/output.json"; }
reported() { grep -qsF -- "$2" "$g/graph/runs/t/$1/report.md"; }
green() { [ "$(code "$1")" -eq 0 ] && says "$1" '"status":"green"' && grep -q '^green: ' "$scratch/$1.out"; }
red() { [ "$(code "$1")" -eq 1 ] && says "$1" '"status":"red"' && grep -q '^red: ' "$scratch/$1.out"; }
# only_two <name>: the step folder holds input.json, output.json and report.md, nothing else.
only_two() {
  # shellcheck disable=SC2012 # plain names
  [ "$(ls "$g/graph/runs/t/$1" | tr '\n' ' ')" = 'input.json output.json report.md ' ]
}
agent='"agent":"graph/tests/fake-agent.sh"'

echo 'case 1: commands that pass'
step pass-commands '{"kind":"commands","dir":"app","run":"echo HELLO-FROM-RUN; ls app"}'
check 'green, exit 0' green pass-commands
check 'report.md has their output' reported pass-commands 'HELLO-FROM-RUN'
check 'they ran from the group folder' reported pass-commands 'page.txt'
check 'output.json is one line of valid JSON' json_valid "$g/graph/runs/t/pass-commands/output.json"
check 'output.json has started and ended' sh -c "grep -Eq '\"started\":\"[0-9:]{8}\",\"ended\":\"[0-9:]{8}\"' '$g/graph/runs/t/pass-commands/output.json'"

echo 'case 2: commands that fail'
step fail-commands '{"kind":"commands","dir":"app","run":"echo BROKEN; exit 3"}'
check 'red, exit 1' red fail-commands
check 'why names the report' says fail-commands 'see graph/runs/t/fail-commands/report.md'
check 'report.md has their output' reported fail-commands 'BROKEN'

echo 'case 3: the agent finishes with a four-heading report'
step good "{\"kind\":\"agent\",\"dir\":\"app\",\"ticket\":\"tickets/good.md\",$agent,\"limit\":10,\"skill\":\"worker\",\"model\":\"model-x\"}"
check 'green, exit 0' green good
check 'why says the report is written' says good 'agent finished, report.md written'
check 'the agent wrote under app/' test -f "$g/app/fake-good.txt"
check 'the plug got SKILL' reported good 'Skill: worker'
check 'the plug got MODEL' reported good 'Model: model-x'
check 'what the agent printed is in the step folder: agent.log' test -f "$g/graph/runs/t/good/agent.log"
step fix "{\"kind\":\"agent\",\"dir\":\"app\",\"ticket\":\"tickets/fix.md\",$agent,\"last\":\"graph/runs/t/fail-commands\"}"
check 'the plug got LAST: the fake fixed app/fixed' sh -c "[ $(code fix) -eq 0 ] && test -f '$g/app/fixed'"

echo 'case 4: the agent fails, or runs past its limit'
step fail "{\"kind\":\"agent\",\"dir\":\"app\",\"ticket\":\"tickets/fail.md\",$agent}"
check 'fails: red, exit 1' red fail
check 'fails: why says agent failed' says fail '"why":"agent failed'
start=$(date +%s)
step slow "{\"kind\":\"agent\",\"dir\":\"app\",\"ticket\":\"tickets/slow.md\",$agent,\"limit\":2}"
check 'too slow: red, exit 1' red slow
check 'too slow: stopped in time' [ $(($(date +%s) - start)) -lt 15 ]
check 'too slow: why says agent cut after 2 s' says slow '"why":"agent cut after 2 s"'
step no-report "{\"kind\":\"agent\",\"dir\":\"app\",\"ticket\":\"tickets/no-report.md\",$agent}"
check 'no report: red, why says agent left no report' sh -c "[ $(code no-report) -eq 1 ] && grep -qF 'agent left no report' '$g/graph/runs/t/no-report/output.json'"
step bad-report "{\"kind\":\"agent\",\"dir\":\"app\",\"ticket\":\"tickets/bad-report.md\",$agent}"
check 'a heading missing: red, why names it' sh -c "[ $(code bad-report) -eq 1 ] && grep -qF 'report.md lacks ## Checked' '$g/graph/runs/t/bad-report/output.json'"

echo 'case 5: the agent writes outside dir'
step outside "{\"kind\":\"agent\",\"dir\":\"app\",\"ticket\":\"tickets/outside.md\",$agent}"
check 'red, exit 1' red outside
check 'why names the path' says outside 'agent touched outside app: tickets/outside.txt'

echo 'case 6: a malformed job'
step two-kinds '{"kind":"commands","kind":"commands","dir":"app","run":"touch app/ran-two-kinds"}'
check 'two kind: red, exit 1' red two-kinds
check 'two kind: nothing ran' [ ! -f "$g/app/ran-two-kinds" ]
check 'two kind: only output.json and report.md written' only_two two-kinds
check 'two kind: report.md says why' reported two-kinds 'kind exactly once'
step three-tickets "{\"kind\":\"agent\",\"dir\":\"app\",\"ticket\":\"tickets/good.md\",\"ticket\":\"tickets/good.md\",\"ticket\":\"tickets/fix.md\",$agent}"
check 'three ticket: red, exit 1' red three-tickets
check 'three ticket: the agent was not called' only_two three-tickets
check 'three ticket: why says it' says three-tickets 'exactly one ticket'
step no-dir '{"kind":"commands","run":"touch app/ran-no-dir"}'
check 'missing dir: red, exit 1' red no-dir
check 'missing dir: nothing ran' [ ! -f "$g/app/ran-no-dir" ]
check 'missing dir: only output.json and report.md written' only_two no-dir
step robot '{"kind":"robot","dir":"app","run":"touch app/ran-robot"}'
check 'unknown kind: red, exit 1' red robot
check 'unknown kind: nothing ran' [ ! -f "$g/app/ran-robot" ]
check 'unknown kind: why names it' says robot "not 'robot'"
step broken '{"kind":"commands","dir":"app","run":"touch app/ran-broken"'
check 'not JSON: red, nothing ran' sh -c "[ $(code broken) -eq 1 ] && [ ! -f '$g/app/ran-broken' ]"

echo 'case 7: the reviewer verdict'
step block "{\"kind\":\"agent\",\"dir\":\"app\",\"ticket\":\"tickets/block.md\",$agent}"
check 'Verdict: block is red' red block
check 'why carries the line after the verdict' says block 'reviewer blocked: The ticket asks for a test of a zero price'
step pass "{\"kind\":\"agent\",\"dir\":\"app\",\"ticket\":\"tickets/pass.md\",$agent}"
check 'Verdict: pass is green' green pass
all_valid() {
  for f in "$g"/graph/runs/t/*/output.json; do json_valid "$f" || return 1; done
}
check 'every output.json is valid JSON' all_valid

exit $fail
