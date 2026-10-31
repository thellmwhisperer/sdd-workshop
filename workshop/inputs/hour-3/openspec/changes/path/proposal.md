## Why

The node of hour 2 runs one step. A ticket needs five: prepare a branch, the worker, the
check, the reviewer, the pull request; and when the check or the reviewer says no, the
worker has to try again, with a limit, or the loop never ends. That order and that limit
are the part a model must not decide: they live in code, in data the group can read.

Proof: `graph/run.sh` is given and its test is green, but there is no `graph/path.jsonl` and no skill under `.github/skills/`: `sh graph/run.sh tickets/001-....md` has no path to walk.

## What Changes

- `graph/path.jsonl`: the five steps, one job per line, with `on_red` and `rounds`.
- `graph/run.sh`: walks the path through `graph/node.sh`, one folder per step visit, back
  on red at most `rounds` times, and writes every event to the run's `journal.jsonl`.
- `graph/tests/test-run.sh`: the path with the fake agent, a local remote and a stand-in
  `gh`.
- The worker and reviewer skills, `.github/skills/worker/` and `.github/skills/reviewer/`,
  that steps 2 and 4 load.

## Capabilities

### New Capabilities
- `graph-path`: the order of the steps, the way back on red, and the journal of a run.

### Modified Capabilities

## Impact

- `graph/run.sh`, `graph/path.jsonl`, `graph/tests/test-run.sh`, `.github/skills/`. No model
  or GitHub is called by the test.
