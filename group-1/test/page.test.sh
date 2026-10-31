#!/bin/sh
# The page exists and has a title.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
name='the page exists and has a title'
if grep -q '<title>[^<][^<]*</title>' "$here/../index.html"; then
  echo "ok $name"
else
  echo "FAIL $name"
  exit 1
fi
