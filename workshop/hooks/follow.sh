#!/bin/sh
# The chief stays with the runs: a Copilot agentStop hook (.github/hooks/workshop.json).
# Copilot speaks only while it has a turn. When the chief ends its turn with a run going in
# the terminal panel, nobody tells the group what happens next: on 31 October, group 4,
# three runs ended, two pull requests opened, one run went red, and the chief said nothing
# for three minutes until the group asked "why are you silent". This hook runs when a turn
# ends and reads the journals under graph/runs/: if a run is still going, or one has ended
# since the chief last spoke, it answers {"decision":"block","reason":...} and Copilot gives
# the chief another turn with the reason as its prompt (Copilot stops after 8 blocks in a
# row). With nothing to tell, the turn ends. The first stop of a session only takes note of
# the runs already finished, so old runs are not announced as news.
# Usage (by Copilot): sh workshop/hooks/follow.sh < stop.json
# WORKSHOP_ROOT and WORKSHOP_PANEL are for its test.
set -u
if [ -n "${WORKSHOP_WORKER:-}" ]; then exit 0; fi
here=$(cd "$(dirname "$0")" && pwd)
root=${WORKSHOP_ROOT:-$(cd "$here/../.." && pwd)}
panel=${WORKSHOP_PANEL:-$here/.panel}
input=$(cat)
session=$(printf '%s' "$input" | sed -n 's/.*"sessionId": *"\([^"]*\)".*/\1/p' | head -n 1)
told="$panel/told-${session:-unknown}"
mkdir -p "$panel"
first=''
if [ ! -f "$told" ]; then first=yes; : > "$told"; fi

# last <file> <key>: the last string value of key on the last matching line.
value() { sed -n "s/.*\"$2\":\"\([^\"]*\)\".*/\1/p" | tail -n 1; }
# What the chief said last, from the transcript Copilot names: a run it already told the
# group about (its name and its link in that message) is not news.
transcript=$(printf '%s' "$input" | sed -n 's/.*"transcriptPath": *"\([^"]*\)".*/\1/p' | head -n 1)
last_said=''
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  last_said=$(grep '"type":"assistant.message"' "$transcript" | tail -n 1)
fi
going=''
ended=''
for j in "$root"/group-*/graph/runs/*/journal.jsonl "$root"/graph/runs/*/journal.jsonl; do
  [ -f "$j" ] || continue
  run=$(dirname "$j")
  rel=${run#"$root"/}
  if grep -q '"event":"run_finished"' "$j"; then
    if grep -qxF "$rel" "$told"; then continue; fi
    printf '%s\n' "$rel" >> "$told"
    [ -z "$first" ] || continue
    status=$(grep '"event":"run_finished"' "$j" | value - status)
    why=$(grep '"event":"run_finished"' "$j" | value - why)
    url=''
    if [ -f "$run/pr.url" ]; then url=$(head -n 1 "$run/pr.url"); fi
    if printf '%s' "$last_said" | grep -qF -- "$(basename "$run")" && { [ -z "$url" ] || printf '%s' "$last_said" | grep -qF -- "$url"; }; then continue; fi
    ended="$ended Run $rel ended $status: $why.${url:+ Pull request: $url.}"
  else
    pid=$(grep -o '"pid":[0-9]*' "$j" | tail -n 1 | cut -d: -f2)
    if [ -n "$pid" ] && kill -0 "$pid" 2> /dev/null; then
      event=$(tail -n 1 "$j" | value - event)
      step=$(tail -n 1 "$j" | sed -n 's/.*"step":\([0-9]*\).*/\1/p')
      going="$going $rel (last event: $event${step:+, step $step});"
    fi
  fi
done
[ -n "$ended$going" ] || exit 0

reason=''
if [ -n "$ended" ]; then
  reason="A run ended:$ended If your last message already said this with the link, end your turn and say nothing more. Else tell the group now, two lines per run: the result in the terminal's words, and the pull request link when there is one; for a red run, the reviewer's reason and that a person decides (read it with sh graph/state.sh graph/runs/<run>). Open graph/runs/<run>/pr.md in the editor panel when there is a pull request."
fi
if [ -n "$going" ]; then
  reason="$reason${reason:+ }A run is still going:$going Do not end your turn while it goes: read its terminal panel (invoke_canvas_action read_terminal_output), say one line to the group only when something new came, sleep 4 at most between looks, until the terminal prints run ...: green or red. Then say the result and the link it prints."
fi
# The reason goes inside a JSON string: no double quotes, backslashes or new lines in it.
reason=$(printf '%s' "$reason" | tr '\n\\"' '   ')
printf '{"decision":"block","reason":"%s"}\n' "$reason"
exit 0
