## 1. The node

- [ ] 1.1 The door: count `kind`, `run` and `ticket` on the raw line of `input.json`, check `dir`; a bad job is red and nothing runs (ticket 000)
- [ ] 1.2 Grey: run the line with `sh -c`, its output to `report.md`, its exit code the colour (ticket 000)
- [ ] 1.3 Blue: call the agent with `SKILL`, `MODEL` and `LAST`, stop it at `limit`, then check the report, the folder and the verdict (ticket 000)
- [ ] 1.4 Always write `output.json` and print `green: <why>` or `red: <why>` (ticket 000)
- [ ] 1.5 `sh graph/tests/test-node.sh` covers the six cases and the verdict, and passes (ticket 000)
