## ADDED Requirements

### Requirement: The path takes a ticket through its steps
`graph/run.sh <ticket>` SHALL run the steps of `graph/path.jsonl` in order through
`graph/node.sh`, each in its own folder under `graph/runs/<ticket>/`; on red it SHALL stop
or go back to the step `on_red` names, at most `rounds` times per step, counted from the
journal; and it SHALL append every event to `journal.jsonl`, never editing it.

#### Scenario: Five steps in order
- **WHEN** every step is green
- **THEN** steps 1 to 5 run once each, in order, and the run ends green

#### Scenario: Back on red
- **WHEN** step 3 is red and its `on_red` is 2
- **THEN** the run goes back to step 2 in a new folder `step-2-work-r2`, whose `last` names the red step's folder

#### Scenario: Rounds exhausted
- **WHEN** step 3 is red again after its `rounds` are used
- **THEN** the run ends red with "step 3 red after 1 rounds: a person decides" when `rounds` is 1

#### Scenario: A stopped run is picked up
- **WHEN** a run stopped halfway, its journal has no `run_finished` and its process is gone, and its ticket is launched again
- **THEN** the run goes on in the same folder, copy and branch from the step after the last green one, and the green steps are not done again

#### Scenario: A live run is left alone
- **WHEN** a run of the ticket is still going and the ticket is launched again
- **THEN** a new run starts in a new folder and the live one is untouched

#### Scenario: The journal
- **WHEN** a run ends
- **THEN** `journal.jsonl` holds one JSON event per line, from `run_created` to `run_finished`, with a `back` event for each round, and `graph/state.sh` prints them
