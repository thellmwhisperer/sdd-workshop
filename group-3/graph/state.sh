#!/bin/sh
# The state of a run, read from its journal: sh graph/state.sh graph/runs/<run>
#
# The journal, journal.jsonl, is the spine of a run: one event per line, appended by
# graph/run.sh as things happen, never edited. It is the only thing trusted to say what
# happened: not the terminal, not anyone's memory. This script folds it into the ticket, the
# phase, one line per step visit, and the rounds used per step, so a person or the chief
# reads a run in a few lines. Exits 0 when the run finished green.
set -eu
run_dir=${1:?usage: sh graph/state.sh graph/runs/<run>}
if [ ! -f "$run_dir/journal.jsonl" ]; then
  printf 'no journal in %s\n' "$run_dir" >&2
  exit 1
fi

# Events in the order of their seq.
sort -t: -k2,2n "$run_dir/journal.jsonl" | awk '
  # str <line> <key>: the first string value of "key", unescaped; num: the first number.
  function str(line, key,   s, i, out, c, n) {
    i = index(line, "\"" key "\":\"")
    if (!i) return ""
    s = substr(line, i + length(key) + 4); out = ""
    while (length(s) > 0) {
      c = substr(s, 1, 1)
      if (c == "\\") {
        n = substr(s, 2, 1)
        if (n == "n") out = out " "; else if (n == "t") out = out " "; else out = out n
        s = substr(s, 3); continue
      }
      if (c == "\"") break
      out = out c; s = substr(s, 2)
    }
    return out
  }
  function num(line, key) {
    if (!match(line, "\"" key "\":-?[0-9]+")) return ""
    return substr(line, RSTART + length(key) + 3, RLENGTH - length(key) - 3)
  }
  /^[ \t]*$/ { next }
  !/^[ \t]*\{.*\}[ \t]*$/ { print "skipped a line that is not JSON: " $0 > "/dev/stderr"; next }
  { events++; e = str($0, "event") }
  e == "run_created" { ticket = str($0, "ticket"); phase = "created" }
  e == "run_resumed" {
    phase = "picked up at step " num($0, "step")
    lines[++n] = sprintf("  stopped halfway, picked up at step %s", num($0, "step"))
  }
  e == "step_started" { phase = "running step " num($0, "step") " " str($0, "name") }
  e == "step_done" {
    lines[++n] = sprintf("  step %s %s: %s: %s", num($0, "step"), str($0, "name"), str($0, "status"), str($0, "why"))
  }
  e == "back" {
    from = num($0, "from"); used[from] = num($0, "round")
    lines[++n] = sprintf("  back from step %s to step %s, round %s", from, num($0, "to"), used[from])
  }
  e == "pull_request" { lines[++n] = "  pull request: " str($0, "url") }
  e == "run_finished" { status = str($0, "status"); phase = "finished " status ": " str($0, "why") }
  END {
    if (phase == "") phase = "no events"
    printf "run %s: %s (%d events)\n", ticket, phase, events
    for (i = 1; i <= n; i++) print lines[i]
    rounds = ""
    for (s in used) rounds = rounds (rounds == "" ? "" : ", ") "step " s ": " used[s]
    print "rounds used: " (rounds == "" ? "none" : rounds)
    exit (status == "green" ? 0 : 1)
  }'
