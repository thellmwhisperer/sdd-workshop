#!/bin/sh
# Starts an hour for one group: marks the hour and, with --base, replaces the group's work
# with the prepared starting point of that hour. The group's own work is kept in
# mine-hour-<N-1>/ inside the group folder; the chief's notes (notes/) stay where they are.
# Usage: sh workshop/start-hour.sh <group-dir> <hour> [--base]
set -eu
. "$(dirname "$0")/lib.sh"

if [ -z "${1:-}" ] || [ ! -d "$1" ]; then
  printf 'no group folder: %s\n' "${1:-}" >&2
  exit 1
fi
dir=$(cd "$1" && pwd)
hour=${2:-}
case $hour in
  '') printf 'hour missing: 1 to 4\n' >&2; exit 2 ;;
  1 | 2 | 3 | 4) ;;
  *) printf 'hour must be 1 to 4\n' >&2; exit 2 ;;
esac
status="$workshop/status.sh"

if [ "${3:-}" = --base ] && [ "$hour" -gt 1 ]; then
  domain=$(domain_of "$dir")
  keep="$dir/mine-hour-$((hour - 1))"
  n=2
  while [ -e "$keep" ]; do
    keep="$dir/mine-hour-$((hour - 1))-$n"
    n=$((n + 1))
  done
  mkdir "$keep"
  for f in "$dir"/* "$dir"/.[!.]* "$dir"/..?*; do
    [ -e "$f" ] || continue
    case $(basename "$f") in mine-hour-* | .hour | notes) continue ;; esac
    mv "$f" "$keep/"
  done
  build_base "$dir" "$domain" "$hour"
  echo "Your work is in $(basename "$keep")/. The base of hour $hour is ready."
elif [ "$hour" -gt 1 ]; then
  if ! sh "$status" "$dir" > /dev/null 2>&1; then
    echo "Hour $((hour - 1)) is not finished. To start from the prepared base instead:"
    echo "  sh workshop.sh start $hour --base"
  fi
  add_inputs "$dir" "$hour"
fi

printf 'hour=%s\n' "$hour" > "$dir/.hour"
echo "Hour $hour started."
sh "$status" "$dir" || true
