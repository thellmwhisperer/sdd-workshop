#!/bin/sh
# Scenarios 22-25: the shared Brisa theme, the header and the front page.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
failed=0
check() {
  if [ "$2" = yes ]; then echo "ok $1"; else echo "FAIL $1"; failed=1; fi
}
has() { grep -qE "$1" "$2" && echo yes || echo no; }

css=no
if [ -f "$here/theme.css" ] && grep -qi '#254F9B' "$here/theme.css" && grep -qi '#C20016' "$here/theme.css"; then css=yes; fi
check '22 theme.css exists and uses the blue and the red' "$css"

link=yes
for p in index promotions till; do
  [ "$(has '<link[^>]*href="theme\.css"' "$here/$p.html")" = yes ] || link=no
  if grep -qE "(src|href)=[\"']?(https?:)?//" "$here/$p.html"; then link=no; fi
done
check '23 the three pages link theme.css and nothing from the network' "$link"

head=yes
for p in index promotions till; do
  [ "$(has '<header' "$here/$p.html")" = yes ] || head=no
  [ "$(has '>Brisa<' "$here/$p.html")" = yes ] || head=no
  for t in index promotions till; do
    [ "$(has "<a[^>]*href=\"$t\.html\"" "$here/$p.html")" = yes ] || head=no
  done
done
check '24 every page has a Brisa header with links to the three pages' "$head"

front=yes
grep -qiE 'promotion' "$here/index.html" || front=no
[ "$(has '<main' "$here/index.html")" = yes ] || front=no
check '25 the front page says what the app is for and links to promotions and till' "$front"

exit "$failed"
