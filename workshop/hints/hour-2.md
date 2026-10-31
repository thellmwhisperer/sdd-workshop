# Hints for hour 2

For the chief only. Give the next hint of the current step, one at a time, in your own
words. Never the answer.

## Step A: the ticket for the node

1. The contract is written: `graph/NODE.md`, one page. Read it with the group before the
   ticket: one program, five steps; a grey step runs commands, a blue step calls an agent.
2. `tickets/000-node.md` is already a full brief. The group's job is to read it and make it
   theirs: is the default `limit` of 300 seconds right for their worker? Is anything in
   `FORBIDDEN` missing? Then a person signs it on the `Signed:` line.
3. The agent of this hour has no skill: the brief and `graph/NODE.md` are all it gets.

## Step B: the node and its test

1. The test comes first: the six cases of `graph/NODE.md` are the checks of
   `graph/tests/test-node.sh`, each one an `  ok` or `  FAIL` line. Run it and read which
   case fails first.
2. The door is the cheapest part and catches the most: count `kind`, `run` and `ticket`
   with grep on the raw line of `input.json`, before reading any value.
3. A blue step is a grey step with three more checks after it: the report has its four
   headings, nothing changed outside `dir`, and no `Verdict: block`. `run_limited` in
   `graph/lib.sh` already stops an agent that runs too long.
4. In the tests the agent is `graph/tests/fake-agent.sh`: the name of the ticket says what
   it does (`slow.md` sleeps, `outside.md` writes in `tickets/`). No model is called.

## Step C: read what the worker built

1. Start with the test, not the node: each `  ok` line is one case of `graph/NODE.md`.
   Ask the group which case they would break first, and where the node stops it.
2. In `graph/node.sh`, find the door first (the job is checked before anything runs),
   then the grey part, then the blue part with its three checks.
3. The group runs `sh graph/tests/test-node.sh` themselves. The node has only met the fake
   agent; the first real agent comes in hour 3, through the path.
