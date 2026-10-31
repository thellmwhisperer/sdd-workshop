# Module 2 · The graph loop

Closing question: What did your node forbid the agent to do, and how did it know?
Given: `graph/NODE.md`, `REPORT.md`, `copilot.sh`, `tests/fake-agent.sh`; `graph/node.sh` as a stub; `tickets/000-node.md` to complete; the tickets of hour 1
The group decides: How long the agent may run; which folder it may touch; whether no report is red
The group builds: `graph/node.sh` and `graph/tests/test-node.sh`, six cases green, read and run by the group. No real agent yet: the node has only met the fake one
Rescue: The prepared base of hour 3: the node and its test green

## Prompt engineering or loop engineering?

Layout: text

- **Prompt engineering:** you write the perfect prompt, read the answer, write the next perfect prompt. Again and again.
- **Loop engineering:** a system does the prompting for you. It sends the prompt, checks the agent's work, prompts again, until done.
- Minimal human intervention. Hold on to the word minimal: we come back to it.

> THE LOOP WRITES THE NEXT PROMPT

## The loop: four stages

Layout: steps

- **Goal:** get the failing checkout tests to pass
- **Action:** open a file, edit some code
- **Observe:** read the output. Green or red?
- **Adjust:** green, next test. Red, try a different fix

Back to the goal. Are we done yet? No. Go again

## A good goal has a stopping condition

Layout: text

- **Bad:** make the checkout faster. No measurable test. The agent runs forever, or stops after one pass and declares victory.
- **Good:** stop when every unit test in the checkout suite passes. The agent knows for sure when it is met.
- The goal is evaluated every time round. In your graph it is the ACCEPTANCE and VERIFY of the ticket.

> "MAKE THE CHECKOUT FASTER" IS "BE HAPPIER"

## What gets built around the loop

Layout: five

- Trigger: a schedule (cron, every night) or a hook (a file changes, a PR opens, slack mention)
- Context: every trip generates output. Compact it, load skills on demand
- Spine: a journal, one event per line. The run's state is read from it, not the terminal
- Tools: MCP or plain APIs. Run code, read files, use the terminal, query a database
- A second agent checks the work: own context, own instructions, maybe another model

## Example of graph runs extractions

Layout: numbers

- **0 of 6** One worker: 6 PRs, none clean through the gate
- **7** Rounds between reviewer and worker in one run
- **4 h** A script waited in "asking user". Nobody was told

## Loop or graph?

Layout: text

- **Loop:** the model decides turn by turn. One plan, the agent runs to the end. This is the common case.
- **Graph:** the path lives in code. Some steps are deterministic code, some carry a model. The model works inside one step, never on the path.
- Results live in files and variables, not in the context. The market also calls it a workflow.

> THE MODEL OR THE CODE

## Workflow, defined

Layout: statement

> WORKFLOWS: LLMS AND TOOLS ORCHESTRATED THROUGH PREDEFINED CODE PATHS

## One node, five steps

Layout: text

- **One node:** one program. A step hands it a job, input.json. Grey: it runs commands and says green or red. Blue: it calls a model with a ticket and a time limit, then checks what it left.
- **Same in, same out:** every step leaves input.json, output.json and report.md. An audit reads five folders of one shape.
- Guardrails are code: the time limit, the folder, the report. This module: the node and its tests. Module 3: the node five times in a row, the path.

> ONE NODE. THE JOB DECIDES.

## Key message

Layout: key

> YOU CAN'T UNIT-TEST A MODEL. YOU CAN UNIT-TEST EVERYTHING AROUND IT.

## Four pitfalls of code that comes out of a loop

Layout: five

- Unverified code: a checker is still an agent. A person reads what ships
- Comprehension debt: more code in the system than humans understand
- Intent debt: it passes the test by relaxing the discount validation. Bad for the business
- Cognitive surrender: "the AI did it, I'm sure it's right"
- The cure: write the why down, keep it current, where the agent reads it

## Where is the human?

Layout: text

- **Writing the goal with its stop:** the ACCEPTANCE and VERIFY of the ticket.
- **Writing the intent where the agent reads it:** AGENTS.md and DOMAIN.md.
- **Reading what comes out:** judging the run, splitting the ticket if it is too big, deciding the merge.

> SUPERVISING, ADJUSTING, REPEATING

## Hands on 2 · Build the node

Layout: hands-on

1. your chief shows the node: a job comes in, input.json. Grey runs commands, blue calls an agent. Out come output.json and report.md
2. decide its limits: how long the agent may run, which folder it may touch, whether an agent that leaves no report is red
3. a worker writes the node's test first, six cases against a fake agent, then node.sh until it is green. No model is called
4. read what the worker built: the test with its six cases and node.sh. Run the test yourselves

You: Build the node.
Chief: Six cases, a fake agent, no model. Test red. Case 3 green. All six green.
You: Show us how it stops an agent that writes in tickets/.
Chief: Case 5: git says what changed, the node calls it red and names the path. A real agent comes in hour 3.

# Decided

- Hour 2 builds one thing: `graph/node.sh` and its six tests. The agent of this hour goes without a skill; the worker and reviewer skills are hour 3 (decision 8198).
- One generic node: the job makes it grey (commands) or blue (an agent); never two node files (decision 8196).
- The job is `input.json`, one flat JSON line in the step's folder; `node.sh` leaves `output.json` and `report.md` beside it; `agent` and `limit` go inside `input.json` (decision 8198).
- `report.md` has four fixed headings, Ticket, Changed, Checked, Not done, written in `graph/REPORT.md`, and the node checks them (decision 8198).
- The plug to the model is `graph/copilot.sh`; in the tests, `graph/tests/fake-agent.sh`. Neither is a node (decision 8198).
- The six cases: commands pass; commands fail; agent ends with a report; agent fails or runs past its limit; agent touches outside its folder; a malformed job (two kind, three ticket) is red and touches nothing (decision 8198).
- Hour 2 ends at step 4: the node built, its test read and run by the group. The two jobs on ticket 001 and reading what the agent left are hour 3 (decision 8208).
- `graph/NODE.md` is open in the panel before ticket 000 is written (decision 8208).
