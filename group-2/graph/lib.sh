#!/bin/sh
# Shared pieces of the graph. Sourced, not run: . graph/lib.sh
#   json_escape <text>              the text as the inside of a JSON string
#   json_get <file|-> <key>         the first value of "key" (a string, unescaped, or a number)
#   json_valid <file>               every line of the file is one valid JSON value
#   run_limited <s> <dir> <log> <command>   runs a command with a time limit
#   journal <run-dir> <event> [fields]       appends one event to the run's journal
# The JSON files of the graph are one line each and are read with these helpers, never with jq.

tab=$(printf '\t')

# json_escape <text>: quotes, backslashes, tabs and newlines escaped; other control
# characters dropped. The result goes between double quotes.
json_escape() {
  printf '%s' "$1" | tr -d '\000-\010\013-\037' \
    | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e "s/$tab/\\\\t/g" \
    | awk 'NR > 1 { printf "\\n" } { printf "%s", $0 }'
}

# json_get <file|-> <key>: the first value of "key": a string, unescaped, or a number as it
# is written. Nothing when the key is not there. - reads the JSON from stdin.
json_get() {
  if [ "$1" != - ] && [ ! -f "$1" ]; then return 0; fi
  awk -v key="$2" '
    {
      s = $0; pat = "\"" key "\""
      while ((i = index(s, pat)) > 0) {
        s = substr(s, i + length(pat))
        if (!match(s, /^[ \t]*:[ \t]*/)) continue
        s = substr(s, RLENGTH + 1)
        if (match(s, /^-?[0-9][0-9.eE+-]*/)) { print substr(s, 1, RLENGTH); exit }
        if (substr(s, 1, 1) != "\"") continue
        s = substr(s, 2); out = ""; done = 0
        while (length(s) > 0) {
          c = substr(s, 1, 1)
          if (c == "\\") {
            n = substr(s, 2, 1)
            if (n == "n") out = out "\n"; else if (n == "t") out = out "\t"
            else if (n == "r") out = out "\r"; else out = out n
            s = substr(s, 3); continue
          }
          if (c == "\"") { done = 1; break }
          out = out c; s = substr(s, 2)
        }
        if (done) { print out; exit }
      }
    }' "$1"
}

# json_valid <file>: true when every line that is not blank is one complete JSON value, and
# there is at least one. A small parser, so the tests can check JSON without node or jq.
json_valid() {
  [ -f "$1" ] || return 1
  awk '
    function ws() { while (pos <= n && substr(s, pos, 1) ~ /[ \t\r]/) pos++ }
    function str(   c) {
      pos++
      while (pos <= n) {
        c = substr(s, pos, 1)
        if (c == "\"") { pos++; return 1 }
        if (c == "\\") {
          c = substr(s, pos + 1, 1)
          if (c ~ /["\\\/bfnrt]/) { pos += 2; continue }
          if (c == "u" && substr(s, pos + 2, 4) ~ /^[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$/) { pos += 6; continue }
          return 0
        }
        if (c == "\t") return 0
        pos++
      }
      return 0
    }
    function num() {
      if (match(substr(s, pos), /^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][-+]?[0-9]+)?/)) { pos += RLENGTH; return 1 }
      return 0
    }
    function members(last,   c) {
      pos++; ws()
      if (substr(s, pos, 1) == last) { pos++; return 1 }
      for (;;) {
        ws()
        if (last == "}") {
          if (substr(s, pos, 1) != "\"" || !str()) return 0
          ws(); if (substr(s, pos, 1) != ":") return 0
          pos++
        }
        if (!value()) return 0
        ws(); c = substr(s, pos, 1); pos++
        if (c == last) return 1
        if (c != ",") return 0
      }
    }
    function value(   c) {
      ws(); c = substr(s, pos, 1)
      if (c == "{") return members("}")
      if (c == "[") return members("]")
      if (c == "\"") return str()
      if (c ~ /[-0-9]/) return num()
      if (substr(s, pos, 4) == "true" || substr(s, pos, 4) == "null") { pos += 4; return 1 }
      if (substr(s, pos, 5) == "false") { pos += 5; return 1 }
      return 0
    }
    /^[ \t\r]*$/ { next }
    { s = $0; n = length(s); pos = 1; seen = 1
      if (!value()) bad = 1
      ws(); if (pos <= n) bad = 1 }
    END { exit (bad || !seen) }' "$1"
}

# stop_tree <pid>: stops a process and everything it started.
stop_tree() {
  for st_child in $(pgrep -P "$1" 2>/dev/null); do stop_tree "$st_child"; done
  kill "$1" 2>/dev/null || true
}
# stop_children <pid>: stops what a process started, and lets it end by itself. Where pgrep
# is missing, it stops the process.
stop_children() {
  if command -v pgrep > /dev/null 2>&1; then
    for sc_child in $(pgrep -P "$1"); do stop_tree "$sc_child"; done
  else
    kill "$1" 2>/dev/null || true
  fi
}

# run_limited <seconds> <folder> <log> <command>: runs the command with sh -c in the folder,
# its output added to the log, and stops it with everything it started when the time is up.
# Returns the command's exit code, or 124 when it ran out of time. The limit is a process in
# the background that sleeps, then stops the command: there is no `timeout` on every system.
# When the command ends first, the sleep is stopped and the watcher ends by itself.
run_limited() {
  rl_mark="$3.timeout"
  rm -f "$rl_mark"
  (cd "$2" && sh -c "$4") >> "$3" 2>&1 < /dev/null &
  rl_pid=$!
  (
    sleep "$1"
    if kill -0 "$rl_pid" 2>/dev/null; then
      : > "$rl_mark"
      stop_children "$rl_pid"
      sleep 1
      stop_tree "$rl_pid"
    fi
  ) > /dev/null 2>&1 < /dev/null &
  rl_watch=$!
  rl_code=0
  wait "$rl_pid" || rl_code=$?
  stop_children "$rl_watch"
  wait "$rl_watch" 2>/dev/null || true
  if [ -f "$rl_mark" ]; then
    rm -f "$rl_mark"
    return 124
  fi
  return "$rl_code"
}

# journal <run-dir> <event> [fields]: appends one event to the run's journal, journal.jsonl,
# as one line: {"seq":N,"ts":"...","event":"<event>",<fields>}. fields are JSON members
# already written, like "step":3,"why":"...". One line per event, never edited.
journal() {
  if [ -f "$1/journal.jsonl" ]; then jr_seq=$(wc -l < "$1/journal.jsonl"); else jr_seq=0; fi
  jr_seq=$((jr_seq + 1))
  printf '{"seq":%s,"ts":"%s","event":"%s"%s}\n' "$jr_seq" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$2" "${3:+,$3}" >> "$1/journal.jsonl"
}
