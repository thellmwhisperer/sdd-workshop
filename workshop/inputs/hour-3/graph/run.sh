#!/bin/sh
# The path: sh graph/run.sh tickets/<ticket>.md, from the group folder.
# Walks graph/path.jsonl, one step per line, each through the node (graph/node.sh) in a
# folder of its own: graph/runs/<run>/step-<N>-<name>/. A new run is a new folder:
# <ticket>, then <ticket>-2, -3. Step 1 gives the run its own copy of the repository, a git
# worktree at graph/runs/<run>/workspace/ on a branch named after the run, and every later
# step runs inside that copy: runs share no files and no branch, so several can go at once.
# Green: the next step. Red: the step's on_red says where to go: "stop" ends the run, a
# number goes back to that step, at most `rounds` times (2 by default); then a person
# decides. Every event is one line of graph/runs/<run>/journal.jsonl, appended, never
# edited: graph/state.sh reads it. A run that stopped halfway (a closed terminal, a machine
# that went to sleep) is picked up where it stopped when its ticket is launched again: same
# folder, same copy, same branch, and the green steps are not done again. The contract is
# graph/PATH.md.
# What the terminal shows, for the people watching: one bold line when each step starts,
# the node's green or red line with its mark, the back line, and at the end the run's
# result with the pull request's link when step 5 opened one (pr.sh leaves it in
# graph/runs/<run>/pr.url). The marks are ✓ in blue and ✗ in orange: a colour-blind
# person tells blue from orange, and the marks say it without colour. NO_COLOR=1 for a log.
set -eu
if [ ! -f graph/node.sh ] || [ ! -f graph/path.jsonl ]; then
  printf 'run it from the group folder, with graph/node.sh and graph/path.jsonl there\n' >&2
  exit 2
fi
# shellcheck source=/dev/null
. graph/lib.sh
esc=$(printf '\033')
if [ -n "${NO_COLOR:-}" ]; then esc=''; fi
bold=${esc:+$esc[1m} blue=${esc:+$esc[34m} orange=${esc:+$esc[38;5;208m} off=${esc:+$esc[0m}
# mark: the node's answer (its last line, green: or red:) with its mark; the rest as it comes.
mark() {
  while IFS= read -r l; do
    case $l in
      green:*) printf '  %s✓ %s%s\n' "$blue" "$l" "$off" ;;
      red:*) printf '  %s✗ %s%s\n' "$orange" "$l" "$off" ;;
      *) printf '%s\n' "$l" ;;
    esac
  done
}
ticket=${1:?usage: sh graph/run.sh tickets/<ticket>.md}
if [ ! -f "$ticket" ]; then
  printf 'red: no ticket file %s\n' "$ticket"
  exit 1
fi
# The run starts from the last commit: the copy of step 1 has what is committed, nothing else.
dirty=$(git status --porcelain -- . ':(exclude)graph/runs' 2> /dev/null | sed 's/^...//' | tr '\n' ' ')
if [ -n "$dirty" ]; then
  printf 'red: commit first, the run starts from the last commit: %s\n' "$dirty"
  exit 1
fi
name=$(basename "$ticket" .md)
mkdir -p graph/runs
# A run of this ticket that stopped halfway is picked up, not started again. Stopped means:
# its journal has no run_finished, and the process that drove it (the pid of its last
# run_created or run_resumed) is gone. A run whose process is alive is still going: it is
# left alone. Taking a stopped run is a mkdir too, so two launches never pick up the same one.
# pid_of <run folder>: the process that last drove the run.
pid_of() {
  grep -E '"event":"run_(created|resumed)"' "$1/journal.jsonl" | tail -n 1 | sed -n 's/.*"pid":\([0-9][0-9]*\).*/\1/p'
}
run=''
candidate=graph/runs/$name
n=2
while [ -z "$run" ] && [ -d "$candidate" ]; do
  if [ -f "$candidate/journal.jsonl" ] && ! grep -q '"event":"run_finished"' "$candidate/journal.jsonl"; then
    pid=$(pid_of "$candidate")
    if [ -n "$pid" ] && ! kill -0 "$pid" 2> /dev/null && mkdir "$candidate/.picked-up-$pid" 2> /dev/null; then
      run=$candidate
    fi
  fi
  candidate=graph/runs/$name-$n
  n=$((n + 1))
done
# Else a new run folder: mkdir takes it or fails, so two runs started at once never share one.
if [ -z "$run" ]; then
  run=graph/runs/$name
  n=2
  until mkdir "$run" 2> /dev/null; do
    run=graph/runs/$name-$n
    n=$((n + 1))
  done
fi
id=$(basename "$run")
workspace=$run/workspace
here=$(pwd)
# The group folder inside the copy: the same path from the root of the repository.
inside=$workspace/$(git rev-parse --show-prefix 2> /dev/null || true)

# finish <green|red> <why>: the last event of the run. After green the copy goes, it is all
# on the branch; after red it stays, for the person who decides.
finish() {
  copy=''
  if [ -d "$workspace" ]; then
    if [ "$1" = green ] && git worktree remove --force "$workspace" > /dev/null 2>&1; then
      copy=removed
    else
      copy="kept at $workspace"
    fi
  fi
  journal "$run" run_finished "\"status\":\"$1\",\"why\":\"$(json_escape "$2")\"${copy:+,\"workspace\":\"$(json_escape "$copy")\"}"
  mark_="${blue}✓"
  [ "$1" = green ] || mark_="${orange}✗"
  printf '\n%s%s run %s: %s%s: %s\n' "$bold" "$mark_" "$run" "$1" "$off" "$2"
  if [ -f "$run/pr.url" ]; then printf '  pull request: %s\n' "$(cat "$run/pr.url")"; fi
  case $copy in
    removed) printf '  the work is on branch %s; the copy is removed\n' "$id" ;;
    kept*) printf '  the copy is %s: a person decides\n' "$copy" ;;
  esac
  printf '  journal: sh graph/state.sh %s\n' "$run"
  if [ "$1" = green ]; then exit 0; fi
  exit 1
}
# esc <text>: the text as the right side of a sed substitution.
esc() { printf '%s' "$1" | sed 's/[&/\]/\\&/g'; }

steps=$(grep -c . graph/path.jsonl)
step=1
prev=''
if [ -f "$run/journal.jsonl" ]; then
  # Where it stopped: the last step event says which step comes next. A step that started
  # and never finished is done again; a green one is not; after a back, its "to".
  step=$(awk '
    function n(key) { if (!match($0, "\"" key "\":[0-9]+")) return 0; return substr($0, RSTART + length(key) + 3, RLENGTH - length(key) - 3) + 0 }
    /"event":"step_started"/ { next_step = n("step") }
    /"event":"step_done"/ { next_step = n("step") + (index($0, "\"status\":\"green\"") ? 1 : 0) }
    /"event":"back"/ { next_step = n("to") }
    END { print (next_step ? next_step : 1) }' "$run/journal.jsonl")
  # The step before it, for last: the folder of the last step that started.
  prev=$(grep '"event":"step_started"' "$run/journal.jsonl" | tail -n 1 | json_get - folder)
  # The copy is there: step 1 is not done again.
  if [ "$step" -eq 1 ] && [ -d "$inside" ]; then step=2; fi
  journal "$run" run_resumed "\"step\":$step,\"pid\":$$"
  printf 'run %s stopped halfway: picked up at step %s\n' "$run" "$step"
else
  journal "$run" run_created "\"ticket\":\"$(json_escape "$ticket")\",\"folder\":\"$run\",\"workspace\":\"$workspace\",\"pid\":$$"
  printf '%srun %s%s: %s, %s steps, its copy at %s\n' "$bold" "$run" "$off" "$ticket" "$steps" "$workspace"
fi
while [ "$step" -le "$steps" ]; do
  # The step's line, with <ticket>, <run> and <workspace> replaced.
  line=$(grep . graph/path.jsonl | sed -n "${step}p" | sed -e 's/[[:space:]]*$//' \
    -e "s/<ticket>/$(esc "$name")/g" -e "s/<run>/$(esc "$id")/g" -e "s/<workspace>/$(esc "$workspace")/g")
  case $line in *'}') ;; *) finish red "line $step of graph/path.jsonl is not a JSON object" ;; esac
  sname=$(printf '%s\n' "$line" | json_get - name)
  # A step visited again gets a fresh folder, -r2, -r3, and the folder of the step before it.
  folder=$run/step-$step-$sname
  last=''
  r=2
  while [ -e "$folder" ]; do
    folder=$run/step-$step-$sname-r$r
    r=$((r + 1))
    last=$prev
  done
  mkdir -p "$folder"
  # last is a full path: the agent reads it from inside the copy.
  extra=",\"last\":\"$(json_escape "${last:+$here/$last}")\""
  if printf '%s' "$line" | grep -Eq '"kind"[[:space:]]*:[[:space:]]*"agent"'; then
    extra=",\"ticket\":\"$(json_escape "$ticket")\"$extra"
  fi
  printf '%s%s}\n' "${line%?}" "$extra" > "$folder/input.json"

  journal "$run" step_started "\"step\":$step,\"name\":\"$(json_escape "$sname")\",\"folder\":\"$folder\""
  kind=$(printf '%s\n' "$line" | json_get - kind)
  visit=''
  if [ -n "$last" ]; then visit=", round $((r - 1))"; fi
  printf '\n%s── step %s of %s: %s (%s%s) ──%s\n' "$bold" "$step" "$steps" "$sname" "$kind" "$visit" "$off"
  # Where the step runs: inside the run's copy once step 1 has made it, else here.
  where=.
  if [ -d "$inside" ]; then where=$inside; fi
  # The node's lines go through mark; its answer is read from output.json, not its exit code.
  (cd "$where" && sh "$here/graph/node.sh" "$here/$folder") 2>&1 | mark
  status=$(json_get "$folder/output.json" status 2> /dev/null || true)
  [ "$status" = green ] || status=red
  why=$(json_get "$folder/output.json" why)
  [ -n "$why" ] || why="graph/node.sh left no output.json"
  if [ "$status" = green ] && [ "$step" -eq 1 ] && [ ! -d "$inside" ]; then
    status=red
    why="step 1 left no copy at $workspace, see graph/PATH.md"
    printf '  %s✗ red: %s%s\n' "$orange" "$why" "$off"
  fi
  journal "$run" step_done \
    "\"step\":$step,\"name\":\"$(json_escape "$sname")\",\"status\":\"$status\",\"why\":\"$(json_escape "$why")\""
  prev=$folder
  if [ "$status" = green ]; then
    step=$((step + 1))
    continue
  fi

  # Red: stop, or go back. Rounds are counted in the journal, not in a variable.
  on_red=$(json_get "$folder/input.json" on_red)
  rounds=$(json_get "$folder/input.json" rounds)
  case $on_red in
    '' | stop) finish red "step $step $sname red: $why" ;;
    *[!0-9]*) finish red "step $step red, and its on_red is not stop or a step number: $on_red" ;;
  esac
  used=$(grep -c "\"event\":\"back\",\"from\":$step," "$run/journal.jsonl" || true)
  [ "$used" -lt "${rounds:-2}" ] || finish red "step $step red after $used rounds: a person decides"
  journal "$run" back "\"from\":$step,\"to\":$on_red,\"round\":$((used + 1))"
  printf '  %s↩ back to step %s, round %s of %s%s\n' "$orange" "$on_red" "$((used + 1))" "${rounds:-2}" "$off"
  step=$on_red
done
finish green "step $steps green"
