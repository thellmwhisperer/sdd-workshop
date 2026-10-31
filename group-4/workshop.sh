#!/bin/sh
# Workshop helper for this group. The chief of staff runs it.
#   sh workshop.sh status             the hour and the progress of its steps
#   sh workshop.sh start N            start hour N with your own work
#   sh workshop.sh start N --base     start hour N from the prepared base; your work is
#                                     kept in mine-hour-<N-1>/, your notes stay
set -eu
here=$(cd "$(dirname "$0")" && pwd)
command=${1:-status}
[ $# -eq 0 ] || shift
case $command in
  status) sh "$here/../workshop/status.sh" "$here" || true ;;
  start) exec sh "$here/../workshop/start-hour.sh" "$here" "$@" ;;
  *)
    sed -n '2,6p' "$0"
    exit 2
    ;;
esac
