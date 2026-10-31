#!/bin/sh
# For the facilitator, before the workshop: rebuilds group-1 to group-4 from scratch at the
# start of an hour (1 by default), with the domains in groups.txt. It deletes what is in
# those folders.
# Usage: sh workshop/setup-groups.sh [hour]
set -eu
. "$(dirname "$0")/lib.sh"
hour=${1:-1}
root=$(dirname "$workshop")
while read -r group domain; do
  [ -n "$group" ] || continue
  rm -rf "${root:?}/$group"
  build_base "$root/$group" "$domain" "$hour"
  echo "$group: $domain, start of hour $hour"
done < "$workshop/groups.txt"
