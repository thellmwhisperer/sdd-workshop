#!/bin/sh
# The single source of the workshop: workshop/source/module-N.md (Javier's slides of each
# module, its row of the day, its closed decisions) and day.md (what holds every hour).
# The decks are built from the same files by the deck generator. This script copies them
# into the blocks between "<!-- source:NAME begin -->" and "<!-- source:NAME end -->" of
# COS.md and .github/skills/module-N/SKILL.md. Edit the source, never those blocks.
# Usage: sh workshop/source/render.sh [--check]   (--check changes nothing; exit 1 if stale)
set -eu
src=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$src/../.." && pwd)
check=${1:-}
tmp=$(mktemp -d "$src/.render.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
stale=0

field() { sed -n "s/^$2: //p" "$1" | head -n 1; }       # field <file> <name>
title() { sed -n 's/^# Module [0-9] · //p' "$1" | head -n 1; }
decided() { sed -n '/^# Decided$/,$p' "$1" | grep '^- ' || true; }

# talk <file>: the slides, as the chief reads them.
talk() {
  awk '
    /^# Decided$/ { exit }
    /^# / { next }
    /^(Closing question|Given|The group decides|The group builds|Rescue): / { next }
    /^Layout: / { next }
    /^## / { print "### " substr($0, 4); chat = 0; next }
    /^> / { print "Key line: **" substr($0, 3) "**"; next }
    /^(You|Chief): / {
      if (!chat) { print "The example on the slide:"; print ""; chat = 1 }
      print "- " $0; next
    }
    { print }
  ' "$1" | sed '/./,$!d' | cat -s
}

# put <file> <name> <block>: the file with the block between the markers of <name>.
put() {
  grep -q "<!-- source:$2 begin" "$1" || { echo "render: no source:$2 markers in $1" >&2; exit 2; }
  awk -v name="$2" -v block="$3" '
    index($0, "<!-- source:" name " begin") == 1 { print; while ((getline l < block) > 0) print l; skip = 1; next }
    index($0, "<!-- source:" name " end") == 1 { skip = 0 }
    !skip { print }
  ' "$1" > "$tmp/out"
  if cmp -s "$1" "$tmp/out"; then return; fi
  if [ "$check" = --check ]; then
    echo "render: $1 does not say what workshop/source says (block source:$2)" >&2
    stale=1
  else
    cp "$tmp/out" "$1"
    echo "render: wrote $1"
  fi
}

for n in 1 2 3 4; do
  m="$src/module-$n.md"
  {
    echo "## What Javier said, slide by slide"
    echo
    echo "These are his slides, in his order, as the decks show them. Quote them; never add a slide"
    echo "or a line he did not say."
    echo
    talk "$m"
    echo "## Javier's closing question"
    echo
    echo "\"$(field "$m" 'Closing question')\""
    echo
    echo "Javier asks it in the room, after the hands on. You never ask it."
    echo
    echo "## Closed decisions"
    echo
    echo "Javier closed these. Follow them; never reopen them, and never ask the group about them again."
    echo
    decided "$m"
  } > "$tmp/module-$n"
  put "$root/.github/skills/module-$n/SKILL.md" module "$tmp/module-$n"
done

{
  echo "| Hour | Javier's talk | The skill with it |"
  echo "|---|---|---|"
  for n in 1 2 3 4; do echo "| $n | $(title "$src/module-$n.md") | \`module-$n\` |"; done
} > "$tmp/talks"
put "$root/COS.md" talks "$tmp/talks"

{
  echo "| Hour | Closing question | Given | The group decides | The group builds | Rescue |"
  echo "|---|---|---|---|---|---|"
  for n in 1 2 3 4; do
    m="$src/module-$n.md"
    echo "| $n · $(title "$m") | $(field "$m" 'Closing question') | $(field "$m" Given) | $(field "$m" 'The group decides') | $(field "$m" 'The group builds') | $(field "$m" Rescue) |"
  done
} > "$tmp/day"
put "$root/COS.md" day "$tmp/day"

{
  echo "Closed for every hour; each hour adds its own in its skill. Follow them; never reopen them."
  echo
  decided "$src/day.md"
} > "$tmp/decided"
put "$root/COS.md" decided "$tmp/decided"

exit "$stale"
