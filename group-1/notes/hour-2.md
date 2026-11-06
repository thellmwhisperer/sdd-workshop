# Hour 2 · The node

## Decided
- Limit: two minutes (120 s), so a stuck agent does not hold up the group.
- Folder: `app` only, so the agent cannot change the agreed tickets.
- An agent that ends without a report (or without its four headings) is red.
- The six cases plus the reviewer's verdict cover what the node needs.
- Ticket 000 signed, 15:23.
- The worker's test had a bug, so hour 2 was taken from the prepared base.

## Done
- `tickets/000-node.md` completed and signed.
- The worker ran ticket 000 in the terminal panel. Job 1 wrote the test and job 2 wrote
  the node, without changing the test. Every check was green except one. The test had an
  unclosed `'` on lines 155 and 159 (the plug receives SKILL, MODEL and LAST). Job 2 named
  the bug and did not edit the test.
- The reference `graph/node.sh` and `graph/tests/test-node.sh` were copied in from
  `workshop/solutions/hour-2/`. `sh graph/tests/test-node.sh` is all green, exit 0. The
  worker's attempt stays in git.
- Read with the group: the door, the grey step and the blue step of `node.sh`, and the six
  cases of the test against the fake agent. The group ran the test themselves.

## For the worker's skill (hour 3)
- Run your own test before handing it over; a test that cannot run is not red, it is broken.
- Do not add behaviour the ticket does not ask for (the worker's node undid the agent's
  changes outside `app/`).

## Pending
- The node uses 300 s when a job gives no limit. The group's 120 s goes into each blue
  job's `input.json` when the path is written in hour 3.
- The node has only met the fake agent. Its first real job is ticket 001, in hour 3.
- Setup notes for this machine: the terminal is PowerShell, so use `;` and not `&&`. Run
  `sh` as `& 'C:\Program Files\Git\bin\sh.exe'`. The Copilot CLI must be signed in.
