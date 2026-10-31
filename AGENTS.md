# AGENTS.md

This repository is a workshop. Each group owns one folder, `group-1` to `group-4`, and
builds there a **graph**: a small program that takes a ticket and turns it into working
code, one short step at a time. One program, the node, runs every step: a grey step runs
commands, a blue step calls a model. Between steps, a check that cannot be talked out of.

Each group builds a different product. The product is described in the group's
`DOMAIN.md`. Everything else is the same for every group.

## Who reads what

- **If your prompt is a ticket (it starts with `# 0`, like `# 001 ·`), or asks you to do one
  (`Do the ticket in`, `Read .github/skills/`), you are a worker.** Implement that ticket
  only, or review it if your skill says so. The ticket is your brief: its SCOPE and
  FORBIDDEN are the fence, its ACCEPTANCE and VERIFY say when it is done, and the STANDING
  ORDERS of your prompt always apply. Nothing else changes. Do not read COS.md.
- **Otherwise a person from a group opened you to talk: you are their chief of staff.
  Read [COS.md](COS.md) before anything else and follow it.**

## Where you may write

Only inside your group's folder. Never in another group's folder, never in `workshop/`,
never in the root of the repository.

## Inside a group folder

| Path | What it holds |
|---|---|
| `DOMAIN.md` | The product: the client's brief and the decisions the group took |
| `openspec/changes/` | What has to be built, as OpenSpec changes |
| `tickets/` | Tickets the chief writes from the changes, each one a brief for one worker |
| `STANDING.md` | The group's standing orders, pasted by `graph/copilot.sh` into every worker's prompt |
| `graph/node.sh` | The node: runs one step from the `input.json` of its folder (`graph/NODE.md`) |
| `graph/path.jsonl` | The path: one line per step; `graph/run.sh` walks it (`graph/PATH.md`) |
| `graph/pr.sh` | Given with `run.sh`: writes the pull request of a run from the ticket's goal, the worker's report and the reviewer's verdict (`graph/runs/<run>/pr.md`), then opens it |
| `graph/copilot.sh` | The plug to the model: the sentence a blue step sends to Copilot |
| `graph/narrate.sh` | Shows an agent at work for people: what it says and what it does, each line with the time |
| `graph/worker.sh` | Hands one ticket to a worker outside a run, in two jobs: the test of VERIFY first, checked red; then the code until it is green, the test unchanged. The chief runs it in the terminal panel so the group watches it live |
| `graph/REPORT.md` | The four headings every agent step's `report.md` has |
| `graph/tests/` | The tests of the node and the path; `fake-agent.sh` stands in for the model |
| `graph/runs/` | What each run left: one folder per run, one per step visit, and `journal.jsonl` |
| `openspec/specs/` | What the app does today: the living documentation. Updated when a change is archived; nobody edits it by hand |
| `app/` | The small web app the graph works on |
| `workshop.sh` | Workshop helper: `sh workshop.sh status` shows the hour and its progress |
| `notes/` | The chief's notes of each hour, and `decisions.tsv`, one row per decision of the day |

## Rules

- A ticket is a brief with seven sections, none empty: GOAL, SCOPE, CONTEXT, ACCEPTANCE,
  VERIFY, FORBIDDEN, REPORT. A ticket with an empty one is not handed to a worker.
- The tests are the judge. "It looks right" is not done; a passing test is.
- Graph runs write only under `graph/runs/`.
- Run a group's tests with `sh graph/tests/run-all.sh` from its folder.
- Write tickets, specs and answers in English.
