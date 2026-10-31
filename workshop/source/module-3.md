# Module 3 · Skills, context and tools

Closing question: What did your reviewer block, and was it right?
Given: The node green; `graph/PATH.md` and its drawing; `graph/run.sh`, the loop that walks the path, with its test green; `graph/pr.sh`, which writes the pull request from the run
The group decides: How many rounds before a person; what the reviewer may block; a person merges or CI does
The group builds: `graph/path.jsonl` and the worker and reviewer skills; then ticket 001 through the five steps, the first time the node meets a real agent, each run in its own copy of the repository and its own branch; ticket 002 whenever they want, even at the same time
Rescue: The prepared base of hour 4: path, skills and loop done, every test green

## The discount is applied after VAT. Fix it.

Layout: text

- The instinct: give the worker the whole repo, the spec, DOMAIN.md and the conversation, and throw it all into the context window. Let it figure it out.
- What happens: it gets lost, touches files that have nothing to do with prices, or fixes the symptom in a generic way that is not how this app works.
- Your graph from module 2 is here. The worker got everything, and the run failed or just about worked. Same problem.

> THROWING CONTEXT INTO THE FIRE

## Four ways to give an agent what it does not know

Layout: five

- Skills: a procedure, with some judgment about when to follow it
- MCP / API: a way to reach the world, read it and act on it
- RAG: pull in what a person wrote, only when it is needed
- Memory: what the agent picked up itself from earlier runs
- Four ways, one at a time. Skills and tools now. RAG and memory in module 4

## Skills: a procedure plus judgment

Layout: prose

- A set of instructions for one kind of task, sometimes with code attached. The pricing skill says: find the pricing module, write the test first, then run the tests.
- A good skill also carries judgment: if the change touches more than one module, stop and ask a person. None of that is in the model's training data.
- The agent pulls the skill in only when the task calls for it.

## Skill or context?

Layout: text

- **System prompt:** the mission. Always loaded, so keep it short.
- **Context:** AGENTS.md and DOMAIN.md. What the chief knows about the whole thing.
- **Skill:** how to do one task. The worker loads it only when it needs it.
- Spec-driven development is one part: the tickets. Around it there is a graph loop, a chief, and skills that go beyond the spec.

> THE CHIEF CARRIES WIDE CONTEXT. THE WORKER CARRIES NARROW CONTEXT.

## MCP / API: talking to the world

Layout: prose

- The skill says run the tests. The worker still cannot run anything on its own. A skill tells it what to do; it does not give it hands.
- MCP is a standard protocol between the agent and every system it needs: the terminal, the repo, GitHub. The server knows how to talk to the system and exposes a call.
- MCP or a cli: both are tools with access outside. In your graph: the tests and git are the worker's hands, GitHub is delivery's.

## RAG and memory, in one minute

Layout: text

- **RAG:** the agent pulls in the relevant piece only when it needs it. Documents a person put there on purpose. DOMAIN.md says the discount goes before VAT.
- **Memory:** what the agent picked up itself. Last time prices were touched the real cause was rounding, and no document said so. When it is fixed, it writes the fix back.
- The difference is where the knowledge comes from. Module 4 is about these two.

> WRITTEN BY SOMEONE: RAG. LEARNED BY THE AGENT: MEMORY.

## Rule of thumb: the four boxes

Layout: steps

- **Somebody wrote it down:** RAG
- **The agent learned it by doing:** memory
- **A procedure, something repeatable:** a skill
- **Look it up or act in the world:** MCP / API

Your worker needs all four. This module gives it the skill and the tools

## Worker and reviewer: one node, two skills

Layout: prose

- One skill for the worker that works, another for the one that reviews. The reviewer is the same node with another skill. The reviewer will be whatever you want it to be.
- The reviewer never touches code. Its report ends with a verdict: pass, or block and why. Block goes back to the worker. Pass goes on to delivery.
- The ideal: a PR in a repo that already has CI, and it allows the human to choose between auto merge or human merge.

## Who writes what?

Layout: text

- **A base team:** the graph, its node, the shared skills and the memory. Every team builds on it.
- **Each product team:** its domain skills, in its own folder, by pull request. The discount goes before VAT.
- Your group is both: module 2 built the base, this module writes the domain.

> THE BASE IS SHARED. THE DOMAIN IS YOURS.

## Key message

Layout: key

> REVIEW. MAKE SURE IT IS ALL RIGHT. THEN OPEN THE PULL REQUEST.

## Who presses merge?

Layout: text

- **A person:** the PR waits. Somebody reads it and presses the button. Slower, and every change has a name next to it.
- **The graph:** CI green means merge. Faster, and the reviewer skill is the only thing between the worker and main.
- One of the questions when you build the graph. There is no right answer: it is your team's.

> YOUR GRAPH, YOUR CALL

## Where is the human?

Layout: text

- **Writing the contract:** what the reviewer may block and what it may not.
- **Putting the rules in the skill:** what the worker cannot know. The discount goes before VAT.
- **Deciding the merge:** a person or the graph. And reading the PR either way.

> THIS YES. THIS NO.

## Hands on 3 · The path

Layout: hands-on

1. write the path with your chief: five lines in path.jsonl, one job per step. Decide the rounds before a person, what the reviewer may block, who merges
2. your chief writes the worker and reviewer skills from DOMAIN.md. Same node, one more line in the job: skill. You correct them
3. given, not built: run.sh, the loop, and pr.sh, which writes the PR. Run the loop's test with your chief: step 3 red once, back to step 2, then green. No model in the test
4. run ticket 001 through the five steps: the node meets a real agent for the first time. Your chief reads the journal and tells you each step. Then 002, alongside if you want

You: Run 001.
Chief: Step 1 green. Step 2, the worker. Step 3 red: a zero price. Back to step 2 with the report. Round 2: green.
You: And the reviewer?
Chief: Step 4: block, no test for an empty basket. Back once more, then pass. Step 5: the PR is open. Do you press merge, or does CI?

# Decided

- Hour 3 shapes the path by giving skills to the blue steps; it runs implementation and review of one ticket, then another, and the runs pile up (decision 8196).
- The path is `graph/path.jsonl`, one JSON line per step; `run.sh` copies the line to the step's `input.json` and adds `last`. New fields against hour 2: `skill`, `on_red`, `rounds` (decision 8198).
- The reviewer never touches code; its report ends `Verdict: pass` or `Verdict: block`; block is red and the path goes back to step 2 (decision 8198).
- A run is a folder and a copy: `graph/runs/<run>/`, named `<ticket>`, then `<ticket>-2`, `-3`; a new run never takes the folder of another. Step 1 makes a git worktree on a branch named after the run; two runs never share files or a branch; `run.sh` refuses uncommitted changes; after green the copy goes, after red it stays (decision 8200).
- A run that stopped halfway is picked up where it stopped, never started again: launching its ticket again finds the run whose journal has no `run_finished` and whose process (the `pid` of its journal) is gone, and goes on in the same folder, the same copy and the same branch, from the step after the last green one; the steps already green are not done again. A run whose process is still alive is left alone, and the ticket gets a new run. It all lives in `run.sh`; the node of hour 2 knows nothing of it (Javi, 24 October: "se pueda resumir una run y no empezar de nuevo"; 31 October: picked up when the ticket is launched again; decision 8213).
- The drawing of the path is `graph/path.png`, a given of hour 3, the same picture as the slide "One node, five steps": the chief opens it in the panel before `graph/PATH.md` and walks the group through it, box by box (Javi, 31 October; decision 8213).
- `run.sh` and its test are given in hour 3, as the node is given in hour 4: the group builds the configuration, the path and the two skills, and runs tickets. The ticket 000-path and its worker are gone; the worker that builds test first, in two checked jobs, is hour 2 (Javi, 31 October: "Proporcionamos run.sh y que hagan runs entonces en la hora 3"; decision 8218).
- `graph/pr.sh` is given with `run.sh`: the deliver line calls it, and the pull request carries the ticket's title and goal, what the worker changed and checked, the reviewer's verdict and the rounds, written to `graph/runs/<run>/pr.md` (Javi, 31 October, after pull request 1 came out with the commit's name and no text: "eso no es serio").
- The first real job of the day is ticket 001 through the path, in this hour. A run that is still going when the hour ends is left going: hour 4 reads what it left (decisions 8208 and 8216).
- The chief writes the worker and reviewer skills from `DOMAIN.md`; the group corrects them (Javi, 30 October; the slide of hands on 3).
