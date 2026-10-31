## ADDED Requirements

### Requirement: One node runs any step from its job
`graph/node.sh <step-folder>` SHALL read `input.json` in that folder, refuse a malformed
job before anything runs, run its commands or call its agent within `limit` seconds, and
always write `output.json` (`status` green or red, `why`, `started`, `ended`) and
`report.md` next to it, exiting 0 for green and 1 for red.

#### Scenario: Commands that pass
- **WHEN** the job is `{"kind":"commands","dir":"app","run":"echo HELLO"}`
- **THEN** the node is green and `report.md` contains `HELLO`

#### Scenario: Commands that fail
- **WHEN** the job's `run` exits 3
- **THEN** the node is red and the why names `report.md`

#### Scenario: The agent finishes
- **WHEN** the agent writes a report with the headings `## Ticket`, `## Changed`, `## Checked` and `## Not done`
- **THEN** the node is green with the why "agent finished, report.md written"

#### Scenario: The agent fails or runs too long
- **WHEN** the agent exits 1, or is still running after `"limit":2`
- **THEN** the node is red and the why says "agent failed" or "agent cut after 2 s"

#### Scenario: The agent writes outside its folder
- **WHEN** the agent of a job with `"dir":"app"` writes `tickets/outside.txt`
- **THEN** the node is red and the why names `tickets/outside.txt`

#### Scenario: A malformed job
- **WHEN** the job has two `kind`, three `ticket`, no `dir`, or a `kind` that is not `commands` or `agent`
- **THEN** the node is red, nothing runs, and the folder holds only `input.json`, `output.json` and `report.md`
