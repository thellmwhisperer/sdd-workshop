# Hints for hour 3

For the chief only. Give the next hint of the current step, one at a time, in your own
words. Never the answer.

## Step A: the path

1. The path is data: `graph/path.jsonl`, one job per line, the five steps of
   `graph/PATH.md`. Each line is what the node of hour 2 already reads, plus `name`,
   `on_red` and `rounds`.
2. The numbers come from the group: `rounds` is the decision of this hour, how many rounds
   before a person; `limit` is the one they decided in hour 2, already in
   `notes/decisions.tsv`. Do not ask it again.
3. Steps 2 and 4 are the same node with another `skill`. The reviewer may take another
   `model` than the worker: another family when Copilot offers one.

## Step B: the skills

1. Two readers, two skills, one node. The worker's says how to turn a ticket into code
   here. The reviewer's says what to block. Neither needs the whole story: the chief
   carries that. You write both from `DOMAIN.md`; the group corrects them.
2. Read the reviewer's skill aloud. Ask: if the reviewer follows this to the letter, will
   any change ever pass in the rounds the group chose?
3. The reviewer blocks what the group decided it may block, at the start of the hour, and
   nothing else. The rules of the business come from `DOMAIN.md`, with numbers it can
   check. It ends its report with `Verdict: pass` or `Verdict: block` and one line of why.

## Step C: run.sh and pr.sh, given, and the loop's test

1. `graph/run.sh` and `graph/pr.sh` are given this hour, like the node was built in hour
   2: `graph/PATH.md` is their contract. Say so before anyone looks for them. Run
   `sh graph/tests/test-run.sh` with the group and read one `ok` line aloud: what it proves.
2. A step visited again gets a new folder, `-r2`; nothing is overwritten. Its `last` is the
   folder of the step that sent it back: that is how the worker reads why it was red.
3. Rounds are counted in the journal, with `grep -c` of the `back` events, never in a
   variable: a run that stops and is read later still knows its rounds.

## Step D: a real run

1. Commit first: the run starts from the last commit. Then one ticket of hour 1, in the
   terminal panel: `sh graph/run.sh tickets/001-....md`. While it runs, read
   `graph/runs/<ticket>/journal.jsonl` with `sh graph/state.sh graph/runs/<ticket>`.
2. The run works in `graph/runs/<ticket>/workspace/`, its own copy of the repository on
   its own branch. Open `app/` there, not in the group folder, to watch the code change.
   Two runs at once never meet: launch the next ticket when the group is ready.
3. If the reviewer blocks, read its `report.md`: was the block about the ticket, or about
   something nobody asked for? That is the skill, not the model: polish it, one change at
   a time, and run again.

## Step E: the pull request

1. The deliver line does what the group decided at the start of the hour: a person
   presses the button, or it merges itself when CI is green. Do not ask it again.
2. Step 5 commits `app/`, pushes the branch and calls `graph/pr.sh`, which writes the pull
   request from the ticket's goal, the worker's report and the reviewer's verdict, and
   opens it. The terminal prints the link when the run ends (`pull request: https://...`).
   Read it together: the text (`graph/runs/<run>/pr.md`), the diff, the checks.
3. A ticket that keeps failing is not fixed by more rounds: the chief splits it into two
   tickets, and the group runs the first one.
