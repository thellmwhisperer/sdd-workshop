#!/bin/sh
# Tests the workshop's guard with tool calls shaped like the ones the chief made in the
# rehearsals of 29 and 30 October. One "  ok" or "  FAIL" line per case.
# Usage: sh workshop/hooks/test-guard.sh
set -u
here=$(cd "$(dirname "$0")" && pwd)
fail=0
s="test-$$"
rm -f "$here/.panel/$s"

call() { printf '%s' "$1" | sh "$here/guard.sh"; }
denied() { # denied <description> <json>
  if call "$2" | grep -q '"permissionDecision":"deny"'; then echo "  ok   $1"; else echo "  FAIL $1"; fail=1; fi
}
allowed() { # allowed <description> <json>
  if call "$2" | grep -q 'deny'; then echo "  FAIL $1"; fail=1; else echo "  ok   $1"; fi
}
bash_call() { printf '{"sessionId":"%s","toolName":"bash","toolArgs":{"command":"%s","description":"x"}}' "$s" "$1"; }

denied 'the task tool (30 Oct: the worker ran as an invisible subagent)' \
  "{\"sessionId\":\"$s\",\"toolName\":\"task\",\"toolArgs\":{\"name\":\"node-worker\",\"mode\":\"background\"}}"
denied 'copilot -p in a command card (29 Oct: the worker log went to /tmp)' \
  "$(bash_call 'cd group-1 && copilot -p \"$(cat tickets/000-node.md)\" --allow-all-tools > /tmp/w.log 2>&1 &')"
denied 'graph/worker.sh in a command card' "$(bash_call 'cd group-4 && sh graph/worker.sh tickets/000-node.md')"
denied 'graph/run.sh in a command card' "$(bash_call 'cd group-4 && sh graph/run.sh tickets/001-percent-off.md')"
worker_writes=$(bash_call 'cat > graph/run.sh.new <<EOF\n# sh graph/run.sh tickets/<ticket>.md\nEOF')
denied 'the chief writing a file that names sh graph/run.sh' "$worker_writes"
if WORKSHOP_WORKER=1 call "$worker_writes" | grep -q deny; then echo '  FAIL a worker (WORKSHOP_WORKER=1) writing a file that names sh graph/run.sh (31 Oct)'; fail=1; else echo '  ok   a worker (WORKSHOP_WORKER=1) writing a file that names sh graph/run.sh (31 Oct)'; fi
denied 'sleep 45 (29 Oct: three minutes of silence)' "$(bash_call 'sleep 45; tail -5 graph/runs/worker-000-node.log')"
denied 'a log written to /var/folders' "$(bash_call 'tail -f /var/folders/4m/x/agent.log')"
allowed 'the node test' "$(bash_call 'cd group-4 && sh graph/tests/test-node.sh')"
allowed 'the path test' "$(bash_call 'cd group-4 && sh graph/tests/test-run.sh')"
allowed 'reading run.sh' "$(bash_call 'cd group-4 && cat graph/run.sh')"
allowed 'the status' "$(bash_call 'cd group-4 && sh workshop.sh status')"
allowed 'sleep 2' "$(bash_call 'sleep 2 && tail -3 graph/runs/worker-000-node.log')"
allowed 'the terminal panel with the worker' \
  "{\"sessionId\":\"$s\",\"toolName\":\"open_canvas\",\"toolArgs\":{\"canvasId\":\"terminal\",\"instanceId\":\"worker-000\",\"input\":{\"command\":\"cd /x/group-4 && sh graph/worker.sh tickets/000-node.md\"}}}"
denied 'writing ticket 000 before graph/NODE.md is open (30 Oct)' \
  "{\"sessionId\":\"$s\",\"toolName\":\"edit\",\"toolArgs\":{\"path\":\"/x/group-4/tickets/000-node.md\",\"old_str\":\"a\",\"new_str\":\"b\"}}"
allowed 'editing another file that names 000-node.md' \
  "{\"sessionId\":\"$s\",\"toolName\":\"edit\",\"toolArgs\":{\"path\":\"/x/group-4/notes/hour-2.md\",\"old_str\":\"a\",\"new_str\":\"tickets/000-node.md\"}}"
allowed 'opening graph/NODE.md in the editor panel' \
  "{\"sessionId\":\"$s\",\"toolName\":\"open_canvas\",\"toolArgs\":{\"canvasId\":\"editor\",\"instanceId\":\"node-md\",\"input\":{\"path\":\"group-4/graph/NODE.md\",\"scope\":\"repo\"}}}"
allowed 'writing ticket 000 once graph/NODE.md is open' \
  "{\"sessionId\":\"$s\",\"toolName\":\"edit\",\"toolArgs\":{\"path\":\"/x/group-4/tickets/000-node.md\",\"old_str\":\"a\",\"new_str\":\"b\"}}"

rm -f "$here/.panel/$s"
exit "$fail"
