# The node

One program, `graph/node.sh`, runs every step of the path. One node, five steps. What a
step does is in its job, not in the program: a **grey step** runs commands, a **blue step**
calls an agent with a ticket: the worker, to build what it says; the reviewer, to judge
what was built. Same ticket, another skill.

```
sh graph/node.sh <step-folder>          run it from the group folder
```

## The job: `input.json`

The step folder holds `input.json`: flat JSON on one line. The node reads it there and
leaves `output.json` and `report.md` next to it. Always those three files, in that folder.
A blue step adds a fourth, `agent.log`: everything the agent printed, in that same folder,
never in a temporary folder outside it. What a run leaves is read in hour 4; nothing of a
run lives outside `graph/runs/`.

| Field | For | What it is |
|---|---|---|
| `kind` | both | `commands` (grey) or `agent` (blue). Exactly once |
| `dir` | both | The folder the step works in, from the group folder: `app`. Must exist |
| `run` | grey | The shell line, run with `sh -c` from the group folder. Exactly once |
| `ticket` | blue | The ticket file, from the group folder. Exactly once |
| `agent` | blue | The plug to call; `graph/copilot.sh` when absent |
| `limit` | blue | Seconds the agent may run; 300 when absent |
| `skill`, `model` | blue | Passed to the plug as `SKILL` and `MODEL`. Optional |
| `last` | blue | The folder of the step the run came from; passed as `LAST`. Optional |

Other fields (`step`, `name`, `on_red`, `rounds`) belong to the path of hour 3: the node
ignores them and keeps them.

## The answer: `output.json`

```
{"status":"green","why":"agent finished, report.md written","started":"10:02:11","ended":"10:04:40"}
```

One line, always written. The node prints `green: <why>` and exits 0, or `red: <why>` and
exits 1.

## What the node does

1. **The door.** Before anything runs: `kind` appears exactly once and is `commands` or
   `agent`; a `commands` job has exactly one `run`; an `agent` job has exactly one
   `ticket`; `dir` exists. Count with grep on the raw line, before parsing. A bad job is
   red, nothing runs, and `report.md` says why.
2. **Grey.** Run the line. Its output is `report.md`; its exit code is the colour.
3. **Blue.** Note `git status --porcelain`. Call
   `sh <agent> <ticket> <dir> <step-folder>/report.md` in the background with `SKILL`,
   `MODEL` and `LAST` exported, and stop it, with everything it started, at `limit`
   seconds (`graph/lib.sh` has `run_limited`). Then, in this order, red when: it was cut
   by the limit ("agent cut after N s"); it failed ("agent failed"); it left no report
   ("agent left no report"); the report lacks one of the four `## ` headings of
   `graph/REPORT.md` ("report.md lacks ## <heading>"); it changed a path outside `<dir>/` and
   `graph/runs/` ("agent touched outside <dir>: <paths>"); the report says
   `Verdict: block` ("reviewer blocked: <the line after it>"). Else green.

## The six cases: `graph/tests/test-node.sh`

Each one a check against `graph/tests/fake-agent.sh`, never a model. Print `  ok   <case>`
or `  FAIL <case>`, like every test here.

1. Commands that pass: green, and `report.md` has their output.
2. Commands that fail: red, and the why names the report.
3. The agent finishes with a four-heading report: green, and `agent.log` is in the step
   folder.
4. The agent fails, or runs past `limit` (`"limit":2` and the ticket `slow.md`): red, and
   the why says which.
5. The agent writes outside `dir`: red, and the why names the path.
6. A malformed job (two `kind`, three `ticket`, no `dir`, an unknown `kind`): red, nothing
   run, nothing written but `output.json` and `report.md`.

And one more, for hour 3: `Verdict: block` is red, `Verdict: pass` is green.

The fake agent does what its ticket's name says: `fail`, `slow`, `outside`, `no-report`,
`bad-report`, `block`, `pass`, `fix`; anything else writes a small file and a good report.

## Try it by hand

```
mkdir -p graph/runs/try/step-1
printf '%s\n' '{"kind":"commands","dir":"app","run":"sh app/check.sh test"}' > graph/runs/try/step-1/input.json
sh graph/node.sh graph/runs/try/step-1
```
