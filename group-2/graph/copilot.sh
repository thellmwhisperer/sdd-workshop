#!/bin/sh
# The plug to the model: sh graph/copilot.sh <ticket> <dir> <report>. The node calls it for
# an agent step, from the group folder, with SKILL, MODEL and LAST from the step's input.json.
# Another model is another file of this shape (claude.sh, codex.sh). Not a node.
# What the agent says and does (graph/narrate.sh) goes to the node's agent.log and,
# when the run has a terminal, to that terminal too, so the group watches it work. Every
# event Copilot wrote is kept next to the report, in copilot.jsonl.
set -eu
# Every path in the brief is absolute: on 31 October a reviewer looked for its skill at the
# root of the repository, was refused three times and gave up without a report.
here=$(pwd)
brief="Your folder is $here: every file you read or write is inside it. Do the ticket in $here/$1. Touch only files under $here/$2/. When you finish, write $3 following $here/graph/REPORT.md exactly. Do not run git. Stop when the report is written."
if [ -n "${SKILL:-}" ]; then brief="Read $here/.github/skills/$SKILL/SKILL.md first. $brief"; fi
if [ -n "${LAST:-}" ]; then brief="$brief The previous step left its result in $LAST/output.json and $LAST/report.md: read them first."; fi
brief="$brief People who do not program are watching you work in a terminal. They see two things: what you say, and the description of each command. So: give every command a short description in plain words, what it is for, never the command itself. Before each step, say in one plain sentence what you are going to do and why; after a test or a check, say in one sentence what it showed."
# Workers cannot see the chat: the group's standing orders go with every brief.
if [ -f STANDING.md ]; then brief="$brief
STANDING ORDERS:
$(cat STANDING.md)"; fi
step=$(dirname "$3")
screen=/dev/null
if (: > /dev/tty) 2> /dev/null; then
  screen=/dev/tty
  printf '\n' > "$screen"
fi
{
  code=0
  WORKSHOP_WORKER=1 copilot -p "$brief" --allow-all-tools --output-format json --add-dir "$2" --add-dir "$step" \
    ${LAST:+--add-dir "$LAST"} --share "$step/conversation.md" ${MODEL:+--model "$MODEL"} 2>&1 || code=$?
  echo "$code" > "$step/copilot.exit"
} | tee "$step/copilot.jsonl" | sh graph/narrate.sh | tee "$screen" | sed "s/$(printf '\033')\[[0-9;]*m//g"
exit "$(cat "$step/copilot.exit")"
