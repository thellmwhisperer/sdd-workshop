## Why

The graph turns a ticket into code in five steps. Some steps run commands (grey), some call
an agent (blue). Writing one program per step means five programs that repeat each other;
one node with a job per step means one program to test, and a step is a line of data.
A model cannot be unit-tested, but everything around it can: the job it gets, the report
it must leave, the folder it must stay in and the time it may take.

Proof: `sh graph/node.sh graph/runs/try/step-1` prints "node.sh: not written yet" and
exits 2.

## What Changes

- `graph/node.sh` reads `input.json` in a step folder and leaves `output.json` and
  `report.md` next to it.
- A door refuses a malformed job before anything runs.
- A `commands` job runs its line; an `agent` job calls the plug (`graph/copilot.sh`, or
  `graph/tests/fake-agent.sh` in the tests) with a time limit and checks the report, the
  folder it wrote in, and the reviewer's verdict.
- `graph/tests/test-node.sh` covers the six cases of `graph/NODE.md` with the fake agent.

## Capabilities

### New Capabilities
- `graph-node`: one program that runs any step of the graph from its job.

### Modified Capabilities

## Impact

- `graph/node.sh` and `graph/tests/test-node.sh`. No model is called by the test.
