#!/bin/sh
# Workshop status of one group: the hour and the progress of each step. No clock: the time
# is kept in the room by the person running the groups, never by the chief.
# The chief runs it before every answer, and the group can run `sh workshop.sh status`.
# Usage: sh workshop/status.sh <group-dir>
# Exits 0 when the current hour is finished, 1 otherwise.
set -eu
dir=$(cd "${1:-.}" && pwd)
group=$(basename "$dir")
product=$(sed -n 's/^# Product: //p' "$dir/DOMAIN.md" 2> /dev/null | head -n 1)

hour=1
started=no
if [ -f "$dir/.hour" ]; then
  hour=$(sed -n 's/^hour=//p' "$dir/.hour")
  started=yes
fi

echo "Workshop status (group $group, $product): hour $hour."
if [ "$started" = no ]; then
  echo "Hour $hour has not started. When the group says so: sh workshop.sh start $hour"
fi

# names <folder> <pattern>: how many names in a folder match the pattern (grep -E), hidden ones aside.
names() {
  if [ -d "$dir/$1" ]; then
    # shellcheck disable=SC2010 # the names here are plain: tickets
    ls "$dir/$1" | grep -cE "$2" || true
  else
    echo 0
  fi
}
# finish <hour> <current step>: prints the end of an hour's steps; true when all are done.
finish() {
  if [ -z "$2" ]; then
    echo "Hour $1 is finished."
    if [ "$1" -lt 4 ]; then
      echo "At the start of a session: welcome the group to hour $(($1 + 1)) and start it, sh workshop.sh start $(($1 + 1))."
    fi
    return 0
  fi
  echo "Current step: $2. Hour $1 is not finished."
  return 1
}

# hour1_progress: prints the steps of hour 1; true when all are done.
hour1_progress() {
  total=$(grep -c '^\*\*Decision:\*\*' "$dir/DOMAIN.md" 2> /dev/null || true)
  pending=$(grep -c '^\*\*Decision:\*\* *_pending_' "$dir/DOMAIN.md" 2> /dev/null || true)
  total=${total:-0}
  pending=${pending:-0}
  change=''
  for c in "$dir"/openspec/changes/*/; do
    [ -d "$c" ] || continue
    name=$(basename "$c")
    case $name in archive | generic-node | path) continue ;; esac
    if [ -f "$c/proposal.md" ]; then change="$change $name"; fi
  done
  product_tickets=$(names tickets '^0*[1-9][0-9]*-.*\.md$')
  # Written tickets are a first draft: the hour ends when the group signs the backlog off.
  ready=no
  if [ -f "$dir/tickets/backlog-ready.md" ]; then ready=yes; fi

  echo 'Hour 1 steps:'
  echo "  A. Decisions in DOMAIN.md: $((total - pending)) of $total taken"
  echo "  B. Product change in openspec/changes/:${change:- not written yet}"
  echo "  C. Product tickets in tickets/: $product_tickets"
  echo "  D. Backlog refined with the group and signed off (tickets/backlog-ready.md): $ready"

  current=''
  if [ "$pending" -gt 0 ]; then current=A
  elif [ -z "$change" ]; then current=B
  elif [ "$product_tickets" -eq 0 ]; then current=C
  elif [ "$ready" = no ]; then current=D
  fi
  finish 1 "$current"
}

# score <test>: "<ok> <checks>" of one test of graph/tests/ ("0 0" when it is not there yet).
score() {
  if [ -f "$dir/graph/tests/$1" ]; then
    result=$(sh "$dir/graph/tests/$1" 2> /dev/null < /dev/null || true)
  else
    result=''
  fi
  printf '%s %s\n' "$(printf '%s\n' "$result" | grep -c '^  ok' || true)" \
    "$(printf '%s\n' "$result" | grep -cE '^  (ok|FAIL)' || true)"
}
# filled <file>: the brief's seven sections, none empty.
filled() {
  [ -f "$1" ] || return 1
  for f in GOAL SCOPE CONTEXT ACCEPTANCE VERIFY FORBIDDEN REPORT; do
    awk -v f="## $f" '$0 == f {on = 1; next} /^## / {on = 0} on && /[^ \t]/ {found = 1} END {exit !found}' "$1" || return 1
  done
}
# signed <file>: the brief has a Signed: line the group filled in.
signed() { grep -q '^Signed: ' "$1" 2> /dev/null && ! grep -q '^Signed: _pending_' "$1"; }

# hour2_progress: prints the steps of hour 2; true when all are done.
hour2_progress() {
  brief=missing
  if filled "$dir/tickets/000-node.md"; then brief='filled, not signed yet'; fi
  if [ "$brief" != missing ] && signed "$dir/tickets/000-node.md"; then brief='filled and signed'; fi
  # shellcheck disable=SC2046
  set -- $(score test-node.sh)
  ok=$1 checks=$2

  echo 'Hour 2 steps:'
  echo "  A. The ticket for the node, tickets/000-node.md: $brief"
  echo "  B. The node's test, graph/tests/test-node.sh: $ok of $checks checks pass"
  echo '  C. Read what the worker built with the group, and they run the test themselves'

  current=''
  if [ "$brief" != 'filled and signed' ]; then current=A
  elif [ "$checks" -eq 0 ] || [ "$ok" -lt "$checks" ]; then current=B
  fi
  finish 2 "$current"
}

# hour3_progress: prints the steps of hour 3; true when steps A to D are done.
hour3_progress() {
  worker=missing
  if [ -f "$dir/.github/skills/worker/SKILL.md" ]; then worker=written; fi
  reviewer=missing
  if [ -f "$dir/.github/skills/reviewer/SKILL.md" ]; then reviewer=written; fi
  steps=$(grep -c . "$dir/graph/path.jsonl" 2> /dev/null || true)
  steps=${steps:-0}
  # shellcheck disable=SC2046
  set -- $(score test-run.sh)
  ok=$1 checks=$2
  reviewed=0 prs=0
  for j in "$dir"/graph/runs/*/journal.jsonl; do
    [ -f "$j" ] || continue
    if grep -q '"event":"step_started","step":4,' "$j"; then reviewed=$((reviewed + 1)); fi
    if grep -q '"event":"step_done","step":5,"name":"[^"]*","status":"green"' "$j"; then prs=$((prs + 1)); fi
  done

  echo 'Hour 3 steps:'
  echo "  A. Skills: worker $worker, reviewer $reviewer"
  echo "  B. The path, graph/path.jsonl: $steps of 5 steps"
  echo "  C. The path's test, graph/tests/test-run.sh (run.sh and pr.sh are given): $ok of $checks checks pass"
  echo "  D. Runs that reached step 4, the reviewer: $reviewed"
  echo "  E. Runs whose step 5 is green, a pull request: $prs. How it merges, the group decides"

  current=''
  if [ "$worker" = missing ] || [ "$reviewer" = missing ]; then current=A
  elif [ "$steps" -ne 5 ]; then current=B
  elif [ "$checks" -eq 0 ] || [ "$ok" -lt "$checks" ]; then current=C
  elif [ "$reviewed" -eq 0 ]; then current=D
  fi
  finish 3 "$current"
}

# hour4_progress: prints the steps of hour 4; true when all are done.
hour4_progress() {
  log="$dir/memory/memory.log"
  sqlite=no
  if command -v sqlite3 > /dev/null 2>&1; then sqlite=yes; fi
  asked=$(grep -c '^ask' "$log" 2> /dev/null || true)
  asked=${asked:-0}
  own=no
  if grep -q '^index.*graph/runs' "$log" 2> /dev/null; then own=yes; fi
  evals=$(grep -c '^eval' "$log" 2> /dev/null || true)
  evals=${evals:-0}

  echo 'Hour 4 steps:'
  echo "  A. Your day indexed (memory.sh index graph/runs notes): sqlite3 found: $sqlite; indexed: $own"
  echo "  B. One case of your own rebuilt: questions asked: $asked"
  echo "  C. Evals, with and without retrieval: $evals"
  echo '  D. One improvement, proposed by the chief: the group decides'

  current=''
  if [ "$sqlite" = no ] || [ "$own" = no ]; then current=A
  elif [ "$asked" -eq 0 ]; then current=B
  elif [ "$evals" -eq 0 ]; then current=C
  fi
  finish 4 "$current"
}

done_hour=1
case $hour in
  1) if hour1_progress; then done_hour=0; fi ;;
  2) if hour2_progress; then done_hour=0; fi ;;
  3) if hour3_progress; then done_hour=0; fi ;;
  4) if hour4_progress; then done_hour=0; fi ;;
esac

notes=''
for n in "$dir"/notes/hour-*.md; do
  [ -f "$n" ] || continue
  n=$(basename "$n" .md)
  notes="${notes:+$notes, }hour ${n#hour-}"
done
echo "Javier's talk of this hour: skill module-$hour. The group's notes in notes/: ${notes:-none yet}"
if [ "$done_hour" -eq 0 ] && [ ! -f "$dir/notes/hour-$hour.md" ]; then
  echo "Next for you: write notes/hour-$hour.md (COS.md, 'Notes'). Ask the group nothing about it."
fi
exit "$done_hour"
