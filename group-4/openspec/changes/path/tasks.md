## 1. The path

- [ ] 1.1 Write `graph/path.jsonl` with the group: five steps, the limits and the rounds it chose
- [ ] 1.2 Write the worker and reviewer skills; the reviewer ends its report with `Verdict: pass` or `Verdict: block`
- [ ] 1.3 `graph/run.sh`: one folder per step visit, `input.json` from the path line plus `ticket` and `last` (ticket 000)
- [ ] 1.4 Red: stop, or back to `on_red` at most `rounds` times, counted from the journal (ticket 000)
- [ ] 1.5 Every event a line of `journal.jsonl`; `sh graph/state.sh` reads it (ticket 000)
- [ ] 1.6 A run that stopped halfway is picked up where it stopped when its ticket is launched again (ticket 000)
- [ ] 1.7 `sh graph/tests/test-run.sh` passes (ticket 000)

## 2. Real runs

- [ ] 2.1 Run a ticket of hour 1 through the five steps: `sh graph/run.sh tickets/001-....md`
- [ ] 2.2 Read with the group what the reviewer blocked, and polish the skills
