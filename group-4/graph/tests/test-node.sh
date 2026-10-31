#!/bin/sh
# Tests of graph/node.sh: sh graph/tests/test-node.sh, from the group folder.
# Builds a throwaway group folder under graph/runs/ (its own git repo, with app/, tickets/
# and a copy of the graph) and runs the node there against graph/tests/fake-agent.sh.
# No model is ever called. Prints `  ok   <case>` or `  FAIL <case>`; exits 1 on any FAIL.
set -u
here=$(cd "$(dirname "$0")" && pwd)
graph=$(cd "$here/.." && pwd)
work="$graph/runs/.test-node-$$"
failed=0
trap 'rm -rf "$work"' EXIT INT TERM

ok() { printf '  ok   %s\n' "$1"; }
fail() { printf '  FAIL %s\n' "$1"; [ -n "${2:-}" ] && printf '       %s\n' "$2"; failed=1; }
check() { if [ "$2" = yes ]; then ok "$1"; else fail "$1" "${3:-}"; fi; }

# A fresh throwaway group folder, committed so that git status starts clean.
setup() {
  rm -rf "$work"
  mkdir -p "$work/graph/tests" "$work/graph/runs" "$work/app" "$work/tickets" "$work/bin"
  cp "$graph/node.sh" "$graph/lib.sh" "$graph/REPORT.md" "$work/graph/"
  cp "$here/fake-agent.sh" "$work/graph/tests/"
  printf 'app\n' > "$work/app/index.txt"
  for t in pass fail slow outside no-report bad-report block work; do
    printf '# %s\n' "$t" > "$work/tickets/$t.md"
  done
  # A sleep that notes how long it was asked to sleep, so the default limit can be seen.
  real_sleep=$(command -v sleep)
  printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "%s/sleeps.log"\nexec %s "$@"\n' "$work" "$real_sleep" > "$work/bin/sleep"
  chmod +x "$work/bin/sleep"
  (cd "$work" && printf 'bin/\nsleeps.log\n' > .gitignore && git init -q . \
    && git add -A && git -c user.name=test -c user.email=test@test commit -qm init) > /dev/null 2>&1
}

# step <name> <json>: writes graph/runs/t/<name>/input.json in the throwaway folder.
step() {
  mkdir -p "$work/graph/runs/t/$1"
  printf '%s\n' "$2" > "$work/graph/runs/t/$1/input.json"
}

# node <name>: runs the node on that step; sets out (what it printed) and code.
node() {
  code=0
  out=$(cd "$work" && PATH="$work/bin:$PATH" sh graph/node.sh "graph/runs/t/$1" 2>&1) || code=$?
}

# Field of the step's output.json.
field() { (. "$graph/lib.sh" && json_get "$work/graph/runs/t/$1/output.json" "$2"); }
has() { case $1 in *"$2"*) echo yes ;; *) echo no ;; esac; }
# only_three <name>: the step folder holds input.json, output.json and report.md, nothing else.
only_three() {
  [ "$(cd "$work/graph/runs/t/$1" && ls -A | tr '\n' ' ')" = "input.json output.json report.md " ] && echo yes || echo no
}
valid() { (. "$graph/lib.sh" && json_valid "$work/graph/runs/t/$1/output.json") && echo yes || echo no; }

blue() { printf '{"kind":"agent","dir":"app","ticket":"tickets/%s.md","agent":"graph/tests/fake-agent.sh"%s}' "$1" "${2:-}"; }

setup

# 1. Commands that pass.
step c1 '{"kind":"commands","dir":"app","run":"echo HELLO-FROM-RUN"}'
node c1
r=no
if [ "$code" = 0 ] && [ "$(field c1 status)" = green ] && [ "$(valid c1)" = yes ] \
  && grep -q HELLO-FROM-RUN "$work/graph/runs/t/c1/report.md" && [ "$(has "$out" "green: ")" = yes ]; then r=yes; fi
check "1 commands that pass: green, exit 0, report.md has their output" $r "code=$code out=$out"

# 2. Commands that fail.
step c2 '{"kind":"commands","dir":"app","run":"echo broken; exit 3"}'
node c2
r=no
if [ "$code" = 1 ] && [ "$(field c2 status)" = red ] && [ "$(has "$(field c2 why)" report.md)" = yes ] \
  && [ "$(has "$out" "red: ")" = yes ]; then r=yes; fi
check "2 commands that fail: red, exit 1, the why names report.md" $r "code=$code out=$out"

# 3. The agent finishes with a four-heading report.
step a3 "$(blue work)"
node a3
r=no
if [ "$code" = 0 ] && [ "$(field a3 status)" = green ] && [ "$(valid a3)" = yes ] \
  && [ -f "$work/graph/runs/t/a3/agent.log" ] && [ -f "$work/app/fake-work.txt" ]; then r=yes; fi
check "3 agent finishes with a four-heading report: green, agent.log in the step folder" $r "code=$code out=$out"

# 4. The agent fails, or runs past its limit.
step a4f "$(blue fail)"
node a4f
r=no
if [ "$code" = 1 ] && [ "$(has "$(field a4f why)" "agent failed")" = yes ]; then r=yes; fi
check "4a agent fails: red, the why says agent failed" $r "code=$code out=$out"
step a4s "$(blue slow ',"limit":2')"
t0=$(date +%s)
node a4s
t1=$(date +%s)
r=no
if [ "$code" = 1 ] && [ "$(has "$(field a4s why)" "agent cut after 2 s")" = yes ] && [ $((t1 - t0)) -lt 20 ]; then r=yes; fi
check "4b agent past its limit of 2 s: red, the why says agent cut after 2 s" $r "code=$code took=$((t1 - t0))s out=$out"

# 5. The agent writes outside dir.
step a5 "$(blue outside)"
node a5
r=no
if [ "$code" = 1 ] && [ "$(has "$(field a5 why)" tickets/outside.txt)" = yes ]; then r=yes; fi
check "5 agent writes outside dir: red, the why names the path" $r "code=$code out=$out"
rm -f "$work/tickets/outside.txt"

# 6. Malformed jobs: red, nothing run, nothing written but output.json and report.md.
step m1 '{"kind":"commands","kind":"commands","dir":"app","run":"touch ran-m1"}'
step m2 '{"kind":"agent","dir":"app","ticket":"tickets/work.md","ticket":"tickets/work.md","ticket":"tickets/work.md","agent":"graph/tests/fake-agent.sh"}'
step m3 '{"kind":"commands","run":"touch ran-m3"}'
step m4 '{"kind":"robot","dir":"app","run":"touch ran-m4"}'
step m5 '{"kind":"commands","dir":"no-such-dir","run":"touch ran-m5"}'
rm -f "$work/app/fake-work.txt"
for m in m1 m2 m3 m4 m5; do
  node $m
  r=no
  if [ "$code" = 1 ] && [ "$(field $m status)" = red ] && [ "$(only_three $m)" = yes ] \
    && [ ! -e "$work/ran-$m" ] && [ ! -e "$work/app/fake-work.txt" ] && [ -s "$work/graph/runs/t/$m/report.md" ]; then r=yes; fi
  case $m in
    m1) label="two kind" ;; m2) label="three ticket" ;; m3) label="no dir" ;;
    m4) label="unknown kind" ;; m5) label="dir that does not exist" ;;
  esac
  check "6 malformed job ($label): red, nothing run, only output.json and report.md" $r "code=$code out=$out"
done

# 7. The verdict.
step v1 "$(blue block)"
node v1
r=no
if [ "$code" = 1 ] && [ "$(has "$(field v1 why)" "reviewer blocked: The ticket asks for a test of a zero price")" = yes ]; then r=yes; fi
check "7a Verdict: block is red, the why carries the line after it" $r "code=$code out=$out"
step v2 "$(blue pass)"
node v2
r=no
if [ "$code" = 0 ] && [ "$(field v2 status)" = green ]; then r=yes; fi
check "7b Verdict: pass is green" $r "code=$code out=$out"

# 8. No report, or a report missing a heading.
step r1 "$(blue no-report)"
node r1
r=no
if [ "$code" = 1 ] && [ "$(has "$(field r1 why)" "agent left no report")" = yes ]; then r=yes; fi
check "8a agent ends without report.md: red, the why says the report is missing" $r "code=$code out=$out"
step r2 "$(blue bad-report)"
node r2
r=no
if [ "$code" = 1 ] && [ "$(has "$(field r2 why)" "report.md lacks")" = yes ] \
  && [ "$(has "$(field r2 why)" "Checked")" = yes ]; then r=yes; fi
check "8b report missing one of the four headings: red, the why names it" $r "code=$code out=$out"

# 9. No limit means 300 seconds.
rm -f "$work/sleeps.log"
step l1 "$(blue pass)"
node l1
r=no
if [ "$code" = 0 ] && grep -qx 300 "$work/sleeps.log" 2>/dev/null; then r=yes; fi
check "9 a job with no limit uses 300 seconds" $r "code=$code sleeps=$(cat "$work/sleeps.log" 2>/dev/null | tr '\n' ' ')"

# 10. Outside means outside dir and graph/runs/: with dir app, a change in tickets/ is red,
# and a change in app/ or graph/runs/ is not.
step o1 "$(blue outside)"
node o1
r1=$code
rm -f "$work/tickets/outside.txt"
step o2 "$(blue work)"
node o2
r=no
if [ "$r1" = 1 ] && [ "$code" = 0 ] && [ -f "$work/app/fake-work.txt" ]; then r=yes; fi
check "10 with dir app, a change in tickets/ is red; app/ and graph/runs/ are allowed" $r "o1=$r1 o2=$code out=$out"

exit $failed
