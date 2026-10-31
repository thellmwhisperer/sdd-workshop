#!/bin/sh
# The app's checks. Usage, from anywhere: sh app/check.sh test|lint|typecheck
#   test       runs every test/*.test.sh with sh, then opens every test/*.test.html in Chrome
#              or Edge without a window and prints the lines its checks wrote (test/check.js).
#              Each line is `ok <name>` or `FAIL <name>`; any FAIL, or a page with no result,
#              and it exits non-zero. BROWSER=<path> picks the browser. While a page runs, the
#              browser keeps a profile of its own in .browser/, removed at the end
#   lint       every .sh parses (sh -n), there is no echo outside test/: the app prints with
#              printf; nothing from Node or a build; test pages load test/check.js, and no
#              page loads anything from the network
#   typecheck  shellcheck when it is installed; otherwise sh -n, and a note that says so.
#              Only the shell scripts: JavaScript has no typecheck here
set -eu
cd "$(dirname "$0")"

# scripts: every .sh of the app, one per line.
scripts() { find . -path ./.browser -prune -o -name '*.sh' -type f -print | sort; }

# lint_problems: for the scripts on stdin, one line per problem.
lint_problems() {
  while read -r f; do
    sh -n "$f" 2> /dev/null || printf '%s: does not parse\n' "$f"
    case $f in
      ./test/* | ./check.sh) ;; # check.sh names the rule it checks
      *) grep -nE '(^|[^A-Za-z0-9_])echo([^A-Za-z0-9_]|$)' "$f" | sed "s|^|$f: echo outside the tests, line |" || true ;;
    esac
  done
}

# parse_problems: for the scripts on stdin, what sh -n says about each.
parse_problems() {
  while read -r f; do sh -n "$f" 2>&1 || true; done
}

# foreign_problems: the app runs in a browser and nowhere else: HTML, CSS and JavaScript as
# the browser loads them. One line per file that belongs to another world (TypeScript,
# Node, npm), per script that calls node, npm or npx, and per JavaScript line that needs
# Node or a build step (require, import, export, process).
foreign_problems() {
  find . -path ./.browser -prune -o \( -name '*.ts' -o -name '*.mjs' -o -name '*.cjs' -o -name 'package.json' \
    -o -name 'package-lock.json' -o -name 'node_modules' \) -print | sort \
    | sed 's|$|: this app is HTML, CSS and JavaScript for a browser, no Node, no build|'
  scripts | while read -r f; do
    [ "$f" != ./check.sh ] || continue # check.sh names the rule it checks
    grep -nE '(^|[^A-Za-z0-9_./-])(node|npm|npx)([^A-Za-z0-9_./-]|$)' "$f" \
      | sed "s|^|$f: calls node, npm or npx, and nothing here runs outside a browser, line |" || true
  done
  find . -path ./.browser -prune -o -name '*.js' -type f -print | sort | while read -r f; do
    grep -nE '(^|[^A-Za-z0-9_.])(require\(|import |export |process\.)' "$f" \
      | sed "s|^|$f: needs Node or a build step, and the browser loads this file as it is, line |" || true
  done
}

# page_problems: one line per test page that does not load check.js, and one per line of a
# page that loads a script or a stylesheet from the network.
page_problems() {
  find . -path ./.browser -prune -o -name '*.test.html' -type f -print | sort | while read -r f; do
    grep -qE "<script[^>]*src=[\"']?([^\"' >]*/)?check\.js" "$f" \
      || printf '%s: does not load check.js, and test pages use test/check.js\n' "$f"
  done
  find . -path ./.browser -prune -o -name '*.html' -type f -print | sort | while read -r f; do
    grep -nE "<(script[^>]*[[:space:]]src|link[^>]*[[:space:]]href)=[\"']?http" "$f" \
      | sed "s|^|$f: the app loads nothing from the network, line |" || true
  done
}

# find_browser: the path of Chrome or Edge: BROWSER when it is set and runs, else the first
# one found. Nothing when there is none.
find_browser() {
  if [ -n "${BROWSER:-}" ] && [ -x "$BROWSER" ]; then
    printf '%s\n' "$BROWSER"
    return
  fi
  for fb in google-chrome google-chrome-stable chromium chromium-browser msedge microsoft-edge; do
    if command -v "$fb" > /dev/null 2>&1; then
      command -v "$fb"
      return
    fi
  done
  fb_local=
  if [ -n "${LOCALAPPDATA:-}" ]; then
    fb_local=$LOCALAPPDATA
    if command -v cygpath > /dev/null 2>&1; then fb_local=$(cygpath -u "$LOCALAPPDATA"); fi
    fb_local="$fb_local/Google/Chrome/Application/chrome.exe"
  fi
  for fb in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
    "/Applications/Chromium.app/Contents/MacOS/Chromium" \
    "/c/Program Files/Google/Chrome/Application/chrome.exe" \
    "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe" \
    "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" \
    "/c/Program Files/Microsoft/Edge/Application/msedge.exe" \
    "$fb_local"; do
    if [ -n "$fb" ] && [ -x "$fb" ]; then
      printf '%s\n' "$fb"
      return
    fi
  done
}

# url <absolute path>: the file as a file:// URL; on Windows under Git Bash, file:///C:/...
url() {
  if command -v cygpath > /dev/null 2>&1; then
    url_path=/$(cygpath -m "$1")
  else
    url_path=$1
  fi
  printf 'file://%s\n' "$url_path" | sed -e 's/%/%25/g' -e 's/ /%20/g' -e 's/#/%23/g' -e 's/?/%3F/g'
}

# native <absolute path>: the path as the browser takes it; on Windows under Git Bash, C:\...
native() {
  if command -v cygpath > /dev/null 2>&1; then cygpath -w "$1"; else printf '%s\n' "$1"; fi
}

# stop_tree <pid>: stops a process and everything it started.
stop_tree() {
  for st_child in $(pgrep -P "$1" 2> /dev/null); do stop_tree "$st_child"; done
  kill "$1" 2> /dev/null || true
}

# dump <url>: the page after its JavaScript ran, as the browser prints it. Every launch gets
# a fresh profile of its own in .browser/, so it never touches the person's Chrome, and no
# crash reporter, so a browser that aborts never opens a dialog. The browser is stopped
# after 30 seconds by a process in the background that sleeps: there is no `timeout` on
# every system. When the browser ends first, the sleep is stopped.
dump() {
  rm -rf "$profile"
  mkdir -p "$profile"
  "$browser" --headless=new --disable-gpu --no-first-run --no-default-browser-check \
    --disable-breakpad --disable-crash-reporter --user-data-dir="$(native "$(pwd)/$profile")" \
    --dump-dom "$1" 2> /dev/null < /dev/null &
  dump_pid=$!
  (
    trap 'kill "$dump_sleep" 2> /dev/null; exit 0' TERM
    sleep 30 &
    dump_sleep=$!
    wait "$dump_sleep"
    stop_tree "$dump_pid"
  ) > /dev/null 2>&1 < /dev/null &
  dump_watch=$!
  wait "$dump_pid" 2> /dev/null || true # quiet: a browser stopped is not a message
  kill "$dump_watch" 2> /dev/null || true
}

# results: the lines inside <pre id="result"> of the dump on stdin, with the three escapes
# of the dump undone.
results() {
  awk '
    !on { i = index($0, "<pre id=\"result\">"); if (!i) next; on = 1; $0 = substr($0, i + 17) }
    {
      j = index($0, "</pre>")
      line = j ? substr($0, 1, j - 1) : $0
      gsub(/&lt;/, "<", line); gsub(/&gt;/, ">", line); gsub(/&amp;/, "\\&", line)
      print line
      if (j) exit
    }'
}

case ${1:-} in
  test)
    failed=0
    for t in test/*.test.sh; do
      [ -f "$t" ] || continue
      sh "$t" || failed=1
    done
    browser=
    # The browser's profile, one at a time: the pages run one after another, never at once.
    profile=.browser/$$
    trap 'rm -rf "$profile"; rmdir .browser 2> /dev/null || true' EXIT
    trap 'exit 1' HUP INT TERM
    for page in test/*.test.html; do
      [ -f "$page" ] || continue
      name=$(basename "$page" .test.html)
      if [ -z "$browser" ]; then
        browser=$(find_browser)
        if [ -z "$browser" ]; then
          printf 'FAIL %s: no browser found: Chrome or Edge is needed, or BROWSER=<path to one>\n' "$name"
          exit 1
        fi
      fi
      lines=$(dump "$(url "$(pwd)/$page")" | results)
      if [ -n "$lines" ]; then printf '%s\n' "$lines"; fi
      if ! printf '%s\n' "$lines" | grep -qE '^(ok|FAIL) '; then
        printf 'FAIL %s: no result (a JavaScript error, or no check ran)\n' "$name"
        failed=1
      elif printf '%s\n' "$lines" | grep -q '^FAIL '; then
        failed=1
      fi
    done
    exit "$failed"
    ;;
  lint)
    problems=$(scripts | lint_problems; foreign_problems; page_problems)
    if [ -n "$problems" ]; then
      printf 'lint: %s\n' "$problems" >&2
      exit 1
    fi
    ;;
  typecheck)
    if command -v shellcheck > /dev/null 2>&1; then
      # shellcheck disable=SC2046 # one argument per script
      shellcheck -S warning -s sh $(scripts)
    else
      printf 'typecheck: shellcheck is not installed, so only sh -n checked the scripts\n'
      problems=$(scripts | parse_problems)
      if [ -n "$problems" ]; then
        printf '%s\n' "$problems" >&2
        exit 1
      fi
    fi
    ;;
  *)
    printf 'usage: sh check.sh test|lint|typecheck\n' >&2
    exit 2
    ;;
esac
