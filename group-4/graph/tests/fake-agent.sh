#!/bin/sh
# A stand-in for graph/copilot.sh in the tests: sh graph/tests/fake-agent.sh <ticket> <dir> <report>
# No model is ever called. It does what the ticket's base name says:
#   fail        exits 1                      slow        sleeps 30 s
#   outside     writes a file under tickets/  no-report   exits 0 and writes nothing
#   bad-report  a report without ## Checked and ## Not done
#   block       a good report with "Verdict: block" and why
#   pass        a good report with "Verdict: pass"
#   fix         writes <dir>/fixed only when LAST is set (a second round), and a good report
#   anything else: a small file under <dir>/ and a good report
# The report carries "Skill: $SKILL" and "Model: $MODEL" when they are set, so a test can
# prove the plug received them.
set -eu
ticket=$1
dir=$2
report=$3
name=$(basename "$ticket" .md)

# good <changed>: a report with the four headings of graph/REPORT.md.
good() {
  {
    printf '## Ticket\n%s: done by the fake agent\n\n' "$ticket"
    printf '## Changed\n- %s\n\n' "$1"
    printf '## Checked\nnothing, the fake agent runs no command\n\n'
    printf '## Not done\nnothing\n'
    if [ -n "${SKILL:-}" ]; then printf '\nSkill: %s\n' "$SKILL"; fi
    if [ -n "${MODEL:-}" ]; then printf 'Model: %s\n' "$MODEL"; fi
  } > "$report"
}

case $name in
  fail) exit 1 ;;
  slow) sleep 30 ;;
  outside)
    printf 'written by the fake agent\n' > tickets/outside.txt
    good tickets/outside.txt
    ;;
  no-report) exit 0 ;;
  bad-report) printf '## Ticket\n%s\n\n## Changed\nnothing\n' "$ticket" > "$report" ;;
  block)
    good nothing
    printf '\nVerdict: block\nThe ticket asks for a test of a zero price and there is none.\n' >> "$report"
    ;;
  pass)
    good nothing
    printf '\nVerdict: pass\n' >> "$report"
    ;;
  fix)
    if [ -n "${LAST:-}" ]; then
      printf 'fixed\n' > "$dir/fixed"
      good "$dir/fixed"
    else
      good nothing
    fi
    ;;
  *)
    printf 'the fake agent did %s\n' "$name" > "$dir/fake-$name.txt"
    good "$dir/fake-$name.txt"
    ;;
esac
