#!/bin/sh
# Runs every test-*.sh in graph/tests/. Exits non-zero if any fails.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
failed=0
for t in "$here"/test-*.sh; do
  [ -f "$t" ] || continue
  if sh "$t"; then
    echo "PASS $(basename "$t")"
  else
    echo "FAIL $(basename "$t")"
    failed=1
  fi
done
exit $failed
