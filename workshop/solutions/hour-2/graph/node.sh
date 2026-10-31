#!/bin/sh
# The node: one program for every step of the path. Run it from the group folder:
#   sh graph/node.sh <step-folder>
# It reads <step-folder>/input.json (flat JSON, one line) and leaves output.json and
# report.md next to it. A grey step ("kind":"commands") runs a shell line; a blue step
# ("kind":"agent") calls an agent with a ticket. The contract is graph/NODE.md.
# Prints "green: <why>" and exits 0, or "red: <why>" and exits 1.
set -eu
step=${1:?usage: sh graph/node.sh <step-folder>}
# shellcheck source=/dev/null
. "$(dirname "$0")/lib.sh"
if [ ! -d "$step" ]; then
  printf 'red: no step folder %s\n' "$step"
  exit 1
fi
input="$step/input.json"
report="$step/report.md"
started=$(date +%H:%M:%S)

# finish <green|red> <why>: writes output.json, says it, and ends.
finish() {
  printf '{"status":"%s","why":"%s","started":"%s","ended":"%s"}\n' \
    "$1" "$(json_escape "$2")" "$started" "$(date +%H:%M:%S)" > "$step/output.json"
  printf '%s: %s\n' "$1" "$2"
  if [ "$1" = green ]; then exit 0; fi
  exit 1
}
# refuse <why>: red before anything runs; report.md holds the reason.
refuse() {
  printf '%s\n' "$1" > "$report"
  finish red "$1"
}
# occurs <key>: how many times "key": appears in the raw line of input.json.
occurs() { grep -o "\"$1\"[[:space:]]*:" "$input" | wc -l | tr -d ' '; }
field() { json_get "$input" "$1"; }

# The door: a malformed job is red, and nothing runs.
[ -f "$input" ] || refuse "no input.json in $step"
if [ "$(grep -c . "$input")" -ne 1 ] || ! json_valid "$input"; then
  refuse "input.json is not one line of valid JSON"
fi
[ "$(occurs kind)" -eq 1 ] || refuse "input.json must have kind exactly once, it has it $(occurs kind) times"
kind=$(field kind)
case $kind in
  commands) [ "$(occurs run)" -eq 1 ] || refuse "a commands step needs exactly one run, it has $(occurs run)" ;;
  agent) [ "$(occurs ticket)" -eq 1 ] || refuse "an agent step needs exactly one ticket, it has $(occurs ticket)" ;;
  *) refuse "kind must be commands or agent, not '$kind'" ;;
esac
dir=$(field dir)
dir=${dir%/}
if [ -z "$dir" ] || [ ! -d "$dir" ]; then refuse "dir '$dir' is not a folder"; fi

# Grey: run the line; its output is the report, its exit code the colour.
if [ "$kind" = commands ]; then
  run=$(field run)
  if sh -c "$run" > "$report" 2>&1 < /dev/null; then
    finish green "commands passed: $run"
  fi
  finish red "commands failed: $run, see $report"
fi

# Blue: call the agent, with a time limit, then judge what it left.
ticket=$(field ticket)
agent=$(field agent)
agent=${agent:-graph/copilot.sh}
limit=$(field limit)
limit=${limit:-300}
SKILL=$(field skill)
MODEL=$(field model)
LAST=$(field last)
[ -f "$ticket" ] || refuse "no ticket file $ticket"
[ -f "$agent" ] || refuse "no agent $agent"
case $limit in '' | *[!0-9]*) refuse "limit must be a whole number of seconds, not '$limit'" ;; esac
if [ -n "$SKILL" ] && [ ! -f ".github/skills/$SKILL/SKILL.md" ]; then
  refuse "no skill .github/skills/$SKILL/SKILL.md"
fi
export SKILL MODEL LAST

# changes: the paths git sees changed or new, one per line, from the repository's root.
changes() {
  git status --porcelain --untracked-files=all 2> /dev/null | sed -e 's/^...//' -e 's/.* -> //' | sort
}
before=$(changes)
rm -f "$report"
NODE_AGENT=$agent NODE_TICKET=$ticket NODE_DIR=$dir NODE_REPORT=$report
export NODE_AGENT NODE_TICKET NODE_DIR NODE_REPORT
code=0
run_limited "$limit" . "$step/agent.log" 'sh "$NODE_AGENT" "$NODE_TICKET" "$NODE_DIR" "$NODE_REPORT"' || code=$?

[ "$code" -ne 124 ] || finish red "agent cut after $limit s"
[ "$code" -eq 0 ] || finish red "agent failed with exit code $code, see $step/agent.log"
[ -s "$report" ] || finish red "agent left no report"
for heading in Ticket Changed Checked 'Not done'; do
  grep -Eq "^## ${heading}[[:space:]]*$" "$report" || finish red "report.md lacks ## $heading"
done
# What changed while the agent ran, outside its dir and outside graph/runs/.
prefix=$(git rev-parse --show-prefix 2> /dev/null || true)
inside="$prefix$dir/"
[ "$dir" != . ] || inside=$prefix
outside=$(changes | BEFORE=$before awk -v dir="$inside" -v runs="${prefix}graph/runs/" '
  BEGIN { n = split(ENVIRON["BEFORE"], b, "\n"); for (i = 1; i <= n; i++) seen[b[i]] = 1 }
  $0 == "" || seen[$0] || dir == "" || index($0, dir) == 1 || index($0, runs) == 1 { next }
  { printf "%s%s", sep, $0; sep = " " }')
[ -z "$outside" ] || finish red "agent touched outside $dir: $outside"
if grep -Eiq '^[#* ]*verdict:[* ]*block' "$report"; then
  why=$(awk 'found && /[^ \t]/ { print; exit } /^[#* ]*[Vv]erdict:/ { found = 1 }' "$report")
  finish red "reviewer blocked${why:+: $why}"
fi
finish green "agent finished, report.md written"
