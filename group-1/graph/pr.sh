#!/bin/sh
# The pull request of a run: sh graph/pr.sh <ticket name> <run name>
# The last command of the deliver line, once the branch is pushed, from the run's copy.
# It is given, like run.sh: a pull request made with `gh pr create --fill` said only the
# name of the commit (31 October, pull request 1: title "001-percent-off", no body). This
# one is written from what the run left behind:
#   the ticket's title and its GOAL;
#   what the worker changed and checked: the report of the first agent step, last visit;
#   what the reviewer said: the report of the last agent step, with its verdict;
#   the run: its name, how many times it went back, where its journal is.
# The text is written to graph/runs/<run>/pr.md first, so it is kept even when gh fails;
# then gh opens the pull request with it: gh pr create --title ... --body-file pr.md.
# The link gh answers goes to graph/runs/<run>/pr.url and to the journal (event
# pull_request): run.sh prints it when the run ends, state.sh shows it, nobody has to ask.
set -eu
name=${1:?usage: sh graph/pr.sh <ticket name> <run name>}
run=${2:?usage: sh graph/pr.sh <ticket name> <run name>}
# shellcheck source=/dev/null
. "$(dirname "$0")/lib.sh"
ticket=tickets/$name.md
if [ ! -f "$ticket" ]; then
  printf 'no ticket file %s\n' "$ticket" >&2
  exit 1
fi
# The run folder: graph/runs/<run>/ in the group folder. From inside the run's copy
# (graph/runs/<run>/workspace/<group>/), it is the folder above the copy.
group=.
folder=graph/runs/$run
if [ ! -f "$folder/journal.jsonl" ]; then
  top=$(git rev-parse --show-toplevel 2> /dev/null || true)
  if [ "$(basename "$top")" = workspace ] && [ -f "$(dirname "$top")/journal.jsonl" ]; then
    folder=$(dirname "$top")
    group=${folder%/graph/runs/*}
  fi
fi
if [ ! -f "$folder/journal.jsonl" ]; then
  printf 'no run %s with a journal under graph/runs/\n' "$run" >&2
  exit 1
fi

# section <file> <heading>: the lines under "## heading", up to the next heading, without
# the blank lines around them.
section() {
  awk -v h="## $2" '
    $0 == h { on = 1; next }
    /^## / { on = 0 }
    on { print }' "$1" | awk 'NF { blank = 0 } !NF { blank++; next } { while (seen && blank-- > 0) print ""; blank = 0; print; seen = 1 }'
}
# The last visit of each step, in step order, from the journal; the first agent step is
# the worker, the last one the reviewer.
visits=$(grep '"event":"step_started"' "$folder/journal.jsonl" | while IFS= read -r line; do
  printf '%s %s\n' "$(printf '%s\n' "$line" | json_get - step)" "$(printf '%s\n' "$line" | json_get - folder)"
done | awk '{ last[$1] = $2 } END { for (s in last) print s, last[s] }' | sort -n)
worker=''
reviewer=''
for v in $(printf '%s\n' "$visits" | cut -d' ' -f2); do
  if [ "$(json_get "$group/$v/input.json" kind)" = agent ]; then
    if [ -z "$worker" ]; then worker=$v; else reviewer=$v; fi
  fi
done
title=$(sed -n 's/^# //p' "$ticket" | head -n 1)
[ -n "$title" ] || title=$name
backs=$(grep -c '"event":"back"' "$folder/journal.jsonl" || true)
case $backs in
  0) back='never went back to the worker' ;;
  1) back='went back to the worker once' ;;
  *) back="went back to the worker $backs times" ;;
esac

{
  section "$ticket" GOAL
  echo
  if [ -n "$worker" ] && [ -f "$group/$worker/report.md" ]; then
    printf '**Changed** (%s)\n' "$(basename "$worker")"
    section "$group/$worker/report.md" Changed
    echo
    echo '**Checked**'
    echo '```'
    section "$group/$worker/report.md" Checked
    echo '```'
    echo
  fi
  if [ -n "$reviewer" ] && [ -f "$group/$reviewer/report.md" ]; then
    verdict=$(sed -n 's/^Verdict: //p' "$group/$reviewer/report.md" | head -n 1)
    notes=$(section "$group/$reviewer/report.md" 'Not done' | grep -v '^Verdict:' | tr '\n' ' ' | sed 's/  */ /g; s/ $//')
    notes=$(printf '%s' "$notes" | cut -c1 | tr '[:lower:]' '[:upper:]')$(printf '%s' "$notes" | cut -c2-)
    printf '**Reviewer** (%s): %s. %s\n\n' "$(basename "$reviewer")" "${verdict:-no verdict}" "$notes"
  fi
  printf 'Run `%s`: %s; journal in `graph/runs/%s/journal.jsonl`.\n' "$run" "$back" "$run"
} > "$folder/pr.md"
url=$(gh pr create --title "$title" --body-file "$folder/pr.md")
printf '%s\n' "$url"
if [ -n "$url" ]; then
  printf '%s\n' "$url" > "$folder/pr.url"
  journal "$folder" pull_request "\"url\":\"$(json_escape "$url")\",\"title\":\"$(json_escape "$title")\""
fi
