#!/bin/sh
# The node: one program for every step of the path. sh graph/node.sh <step-folder>
# Run it from the group folder. The contract is graph/NODE.md: it reads <step-folder>/input.json,
# runs its commands (grey) or calls its agent (blue), and always leaves output.json and
# report.md next to it. Prints green: <why> and exits 0, or red: <why> and exits 1.
set -u
. "$(dirname "$0")/lib.sh"

step=${1:?usage: sh graph/node.sh <step-folder>}
step=${step%/}
input="$step/input.json"
report="$step/report.md"
started=$(date +%H:%M:%S)

# finish <green|red> <why>: writes output.json, prints the answer and exits.
finish() {
  printf '{"status":"%s","why":"%s","started":"%s","ended":"%s"}\n' "$1" "$(json_escape "$2")" \
    "$started" "$(date +%H:%M:%S)" > "$step/output.json"
  printf '%s: %s\n' "$1" "$2"
  if [ "$1" = green ]; then exit 0; fi
  exit 1
}
# refuse <why>: a bad job. Nothing runs; report.md says why.
refuse() {
  printf 'The node refused this job: %s\nNothing was run. The contract is graph/NODE.md.\n' "$1" > "$report"
  finish red "bad job: $1"
}
# count <key>: how many times "key": appears on the raw line of input.json.
count() { grep -o "\"$1\"[[:space:]]*:" "$input" | wc -l | tr -d ' '; }
# q <text>: the text quoted for sh -c.
q() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }

if [ ! -d "$step" ]; then
  printf 'red: no step folder %s\n' "$step"
  exit 1
fi
[ -f "$input" ] || refuse "no input.json in $step"

# The door: counted on the raw line, before parsing.
[ "$(count kind)" = 1 ] || refuse "kind must appear exactly once, found $(count kind)"
kind=$(json_get "$input" kind)
case $kind in
  commands) [ "$(count run)" = 1 ] || refuse "a commands job needs exactly one run, found $(count run)" ;;
  agent) [ "$(count ticket)" = 1 ] || refuse "an agent job needs exactly one ticket, found $(count ticket)" ;;
  *) refuse "kind must be commands or agent, not '$kind'" ;;
esac
[ "$(count dir)" = 1 ] || refuse "dir must appear exactly once, found $(count dir)"
dir=$(json_get "$input" dir)
dir=${dir%/}
[ -n "$dir" ] || refuse "dir is empty"
[ -d "$dir" ] || refuse "dir $dir does not exist"

# Grey: the line, its output the report, its exit code the colour.
if [ "$kind" = commands ]; then
  run=$(json_get "$input" run)
  code=0
  sh -c "$run" > "$report" 2>&1 < /dev/null || code=$?
  if [ "$code" = 0 ]; then finish green "commands passed, output in $report"; fi
  finish red "commands failed with exit $code, see $report"
fi

# Blue: the agent, within its limit, then its report, its folder and its verdict.
ticket=$(json_get "$input" ticket)
agent=$(json_get "$input" agent)
[ -n "$agent" ] || agent=graph/copilot.sh
limit=$(json_get "$input" limit)
[ -n "$limit" ] || limit=300
case $limit in
  '' | *[!0-9]*) refuse "limit must be whole seconds, not '$limit'" ;;
esac
SKILL=$(json_get "$input" skill)
MODEL=$(json_get "$input" model)
LAST=$(json_get "$input" last)
export SKILL MODEL LAST

# snapshot: one line per changed path of the group folder, path and checksum, sorted.
prefix=$(git rev-parse --show-prefix 2>/dev/null || true)
snapshot() {
  git status --porcelain -uall -- . 2>/dev/null | while IFS= read -r line; do
    p=${line#???}
    case $p in *' -> '*) p=${p#* -> } ;; esac
    p=${p#\"}; p=${p%\"}
    p=${p#"$prefix"}
    if [ -f "$p" ]; then sum=$(cksum < "$p"); else sum=gone; fi
    printf '%s\t%s\n' "$p" "$sum"
  done | sort
}

rm -f "$report" "$step/agent.log"
before=$(snapshot)
: > "$step/agent.log"
code=0
run_limited "$limit" . "$step/agent.log" "sh $(q "$agent") $(q "$ticket") $(q "$dir") $(q "$report")" || code=$?
after=$(snapshot)

if [ "$code" = 124 ]; then finish red "agent cut after $limit s"; fi
if [ "$code" != 0 ]; then finish red "agent failed with exit $code, see $step/agent.log"; fi
[ -f "$report" ] || finish red "agent left no report"
for heading in Ticket Changed Checked 'Not done'; do
  grep -Eq "^(## )?$heading:?" "$report" || finish red "report.md lacks $heading:"
done
# outside_paths: the changed paths on stdin that are not under dir/ or graph/runs/.
outside_paths() {
  while IFS= read -r p; do
    case $p in
      '' | "$dir"/* | graph/runs/*) ;;
      *) printf '%s ' "$p" ;;
    esac
  done
}
outside=$(printf '%s\n%s\n' "$before" "$after" | sort | uniq -u | cut -f1 | sort -u | outside_paths)
outside=${outside% }
[ -z "$outside" ] || finish red "agent touched outside $dir: $outside"
if grep -q '^Verdict: block' "$report"; then
  finish red "reviewer blocked: $(sed -n '/^Verdict: block/{n;p;q;}' "$report")"
fi
finish green "agent finished, report.md written"
