# The path

The node of hour 2 runs one step. The path says which steps, in which order, and where to
go when one is red. It is data, `graph/path.jsonl`, one line per step; `graph/run.sh` walks
it. The path lives in code: a model works inside one step, never on the path.

```
1 prepare (grey) -> 2 work (blue) -> 3 check (grey) -> 4 review (blue) -> 5 deliver (grey)
                         ^______ red: back to step 2 ______|__________________|
                                 at most `rounds` times, then a person decides
```

The same drawing as an image: `graph/path.png`.

## `graph/path.jsonl`

```
{"step":1,"name":"prepare","kind":"commands","dir":".","run":"git worktree add <workspace> -b <run>","on_red":"stop"}
{"step":2,"name":"work","kind":"agent","dir":"app","skill":"worker","agent":"graph/copilot.sh","limit":300,"on_red":"stop"}
{"step":3,"name":"check","kind":"commands","dir":"app","run":"sh app/check.sh lint && sh app/check.sh test","on_red":2,"rounds":2}
{"step":4,"name":"review","kind":"agent","dir":"app","skill":"reviewer","agent":"graph/copilot.sh","limit":180,"on_red":2,"rounds":2}
{"step":5,"name":"deliver","kind":"commands","dir":"app","run":"git add -A app && git commit -qm <ticket> && git push -u origin HEAD && sh graph/pr.sh <ticket> <run>","on_red":"stop"}
```

Each line is a job for the node, plus three fields for the path: `name`, `on_red` (`"stop"`,
or the number of the step to go back to) and `rounds` (how many times; 2 when absent).
Three words in a `run` line are replaced before the node sees it: `<ticket>` is the ticket's
name (`001-basket-total`), `<run>` is the run's name (`001-basket-total`, then
`001-basket-total-2`, `-3`), `<workspace>` is the run's copy, `graph/runs/<run>/workspace`.

## A run is a folder and a copy

A run is `graph/runs/<run>/`: the journal, one folder per step visit, and the copy of the
repository the run works on. Nothing in it is overwritten. The same ticket launched
while its first run still goes is `<ticket>-2`, with its own folder, its own copy and its
own branch; launched after its run stopped halfway, it picks that run up (below).

- **Step 1 makes the copy**: `git worktree add graph/runs/<run>/workspace -b <run>`, a
  git worktree from the last commit, on a branch named after the run. If that branch or
  that folder already exists, git refuses and step 1 is red: nothing is touched.
- **Every later step runs inside the copy**, in the group's folder there. `dir`, `ticket`,
  `agent` and the skills are read from the copy; `app/` in the group folder never changes
  while a run goes. The step's own folder stays in `graph/runs/<run>/`, outside the copy.
- **The run starts from the last commit.** `run.sh` refuses to start while the group folder
  has uncommitted changes: commit first, or what you just wrote is not in the copy.
- **Runs do not wait for each other.** Two tickets, or the same ticket twice, can go at
  once: separate folders, separate copies, separate branches.
- **A run that stopped halfway is picked up, not started again.** A closed terminal or
  a laptop that went to sleep stops a run in the middle. Launching the same ticket again
  finds it: a run of that ticket whose journal has no `run_finished` and whose process is
  gone (the `pid` of its journal; `kill -0 <pid>` fails). It goes on in that same folder,
  copy and branch, from the step after the last green one: a step that started and never
  finished is done again, a green one is not, and after a `back` it goes to its `to`. If
  the copy is there, step 1 is not done again. A run whose process is alive is still
  going: it is left alone, and the ticket gets a new run.
- **Step 5 pushes the run's branch** and opens the pull request with `graph/pr.sh`, given
  like `run.sh`: `sh graph/pr.sh <ticket> <run>` writes `graph/runs/<run>/pr.md` from what
  the run left (the ticket's title and GOAL; what the worker changed and checked, from the
  report of the first agent step; the reviewer's verdict and notes, from the report of the
  last one; how many times the run went back, from the journal) and opens the pull request
  with that title and that text. A pull request made with `gh pr create --fill` carried
  only the commit's name. After green, `run.sh` removes the copy (it is all on the
  branch). After red it keeps it, for the person who decides.

## `graph/run.sh`

`sh graph/run.sh tickets/<ticket>.md`, from the group folder.

1. Refuses while `git status` of the group folder is not clean. Looks for a run of this
   ticket that stopped halfway (above) and takes it with `mkdir <run>/.picked-up-<pid>`,
   so two launches never pick up the same one; it goes on from its step and writes
   `run_resumed` (the step, and its own `pid`). Else it takes a new `graph/runs/<run>/`
   (`<ticket>`, then `-2`, `-3`: with `mkdir`, so two runs started together never share
   one) and starts its `journal.jsonl` with `run_created` and its own `pid`. `last` of
   the first step after a pick-up is the folder of the last step that started.
2. For step N with name X: makes `graph/runs/<run>/step-N-X/`, writes there
   `input.json` = the path line with `<ticket>`, `<run>` and `<workspace>` replaced, plus
   `"ticket":"<ticket>"` for an agent step, plus `"last":"<folder>"`: empty on a step's
   first visit, else the full path of the step that came just before. Then
   `sh graph/node.sh <that folder>`, from inside the copy when it exists, else from the
   group folder. A green step 1 that left no copy at `<workspace>` is red.
3. Green: the next step. After the last step green, the run is green and the copy is
   removed.
   The terminal, for the people watching: one bold line when each step starts
   (`── step 3 of 5: check (commands, round 2) ──`), the node's `green:` or `red:` line with
   its mark (✓ blue, ✗ orange: a colour-blind person tells them apart), `↩ back to step 2,
   round 1 of 2`, and at the end `✓ run graph/runs/<run>: green: ...` followed by
   `pull request: <link>` when `pr.sh` opened one, where the copy went, and the
   `state.sh` line to read the journal. `NO_COLOR=1` prints the same without colour.
4. Red: `on_red` `"stop"` (or absent) ends the run red. A number goes back to that step and
   counts one round for the red step. When the red step has used its `rounds`, the run ends
   red: "step N red after R rounds: a person decides". The copy is kept.
5. A step visited again gets a fresh folder, `step-N-X-r2`, `-r3`. The earlier one is kept.

The journal is one event per line, appended, never edited: `run_created` (with the
workspace and the `pid` of `run.sh`), `run_resumed` (the step it goes on from and the new
`pid`), `step_started`, `step_done` (status and why), `back` (from, to, round),
`run_finished` (status, why, and what became of the workspace); `pull_request` (url,
title), written by `pr.sh`, which also leaves the link in `graph/runs/<run>/pr.url`.
Rounds are counted by
reading it (`grep -c` of the `back` events of that step), never by a variable.
`sh graph/state.sh graph/runs/<run>` folds it: the phase, one line per step visit, the
rounds used.

## The test: `graph/tests/test-run.sh`

A throwaway group folder with the real `node.sh`, `run.sh`, `pr.sh`, `state.sh` and `lib.sh`; a path
of five steps where step 3 is `test -f app/fixed` and the agent is
`graph/tests/fake-agent.sh`; a local bare repository as `origin` and a `gh` that only writes
what it was asked. Nothing reaches a model or GitHub.

- The ticket `fix.md`: 1, 2, 3 red, back to 2 (round 1), 3 green, 4, 5 green; the journal
  has the `back` event; `state.sh` prints the steps and the round; the branch `fix` on the
  remote has `app/fixed` and the group folder's `app/` does not; the copy is gone; `pr.md`
  of the run has the ticket's goal, the worker's change and the reviewer's line, and `gh`
  was asked for that title and that file.
- `rounds` 1 and an agent that never fixes: the run ends red, "a person decides", and the
  copy is kept.
- `on_red` `"stop"` on a red step 1: the run ends at once.
- A branch that already exists: step 1 red, nothing made.
- Uncommitted changes in the group folder: refused before any run folder exists.
- The same ticket twice at once: two runs, two branches, both green.
- A run cut in step 3 (its `run.sh` killed): launched again, it says where it picked up,
  makes no new folder, and goes 1 2 3, then 3 4 5; the work of step 2 is on the branch.
- A run cut once step 1 made the copy: launched again, it goes on at step 2.
- A run whose process is alive: the ticket gets a new run and the live one is untouched.
