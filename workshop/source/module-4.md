# Module 4 · Memory that improves the system

Closing question: What happened in your case, and what changed after it?
Given: The memory tool, `CASES.md` and the example team's runs
The group decides: Which case to open; which question to ask of their own runs; which improvement to make
The group builds: The case rebuilt; an index of their own runs; one eval with and without retrieval; one improvement
Rescue: The example team's runs, when their own are too few

## How do you remember?

Layout: text

- **Right now:** what you are holding in your head this minute.
- **Facts:** what you know is true, like the discount going before VAT.
- **Skills:** how to do things, like writing backwards on glass.
- **Experience:** the three hours lost on the wrong Kubernetes cluster.

> A WELL-DESIGNED AGENT NEEDS THE SAME FOUR

## Four types of agent memory (CoALA, Princeton)

Layout: five

- Working: the context window. Like RAM: fast, volatile, with a ceiling
- Semantic: what it knows in general. In practice, markdown files such as AGENTS.md
- Procedural: how to do things. SKILL.md, loaded only when the task matches
- Episodic: what happened before and what it learned. The hardest to get right
- Thermostat: working memory. Password-reset bot: plus a skill. Coding agent: all four

## The four memories in the graph you built

Layout: steps

- **Working:** the worker's clean window, one per ticket
- **Semantic:** AGENTS.md and DOMAIN.md
- **Procedural:** the skills from module 3
- **Episodic:** the SQLite with your runs. This module

Memory is what separates a chatbot from an agent

## Episodic memory: the hardest one

Layout: prose

- Why the conversations: to recall past conversations and their context, the human's and the agent's. A decision is backed by a human's word, not by a metric. When something goes wrong you rebuild the timeline step by step: what the chief of staff said, what the agent answered.
- What you do with it: run times, cost, which model is better, repeated patterns that become a skill. The system improves as it is used. Distil on top of the source, never instead of it.

## RAG or memory?

Layout: text

- **RAG** reads what a person wrote on purpose: specs, docs, tickets.
- **Memory** reads what the agent lived: runs, verdicts, what it fixed and how.
- Your SQLite holds both. The specs and tickets are RAG. The runs and verdicts are memory.

> WHAT YOU WROTE. WHAT IT LIVED.

## Key message

Layout: statement

> EVERY RUN IS DATA. THE SYSTEM GETS BETTER ONLY IF YOU KEEP IT AND LOOK AT IT.

## What teams running this can see in their data

Layout: numbers

- **4 h** A run waited 4 h in review. Nobody was told
- **86%** One reviewer model was right in 86% of 32 cases
- **0 of 6** One worker model: 6 PRs, none clean through the gate

## Your corpus: what you and your system wrote

Layout: five

- The chief's tickets
- Worker reports and reviewer verdicts
- Time and cost per step
- The chief's handover
- Conversations: you with the chief, the chief with its agents

## Key message

Layout: key

> NOT A MONITORING DASHBOARD. EVERY DECISION IS BACKED BY A HUMAN'S WORD.

## RAG in a nutshell

Layout: text

- **Index:** cut what the system produced into pieces and store them.
- **Retrieve:** find the pieces that answer your question.
- **Generate:** the model answers with those pieces in its context.
- In this module: one question, searched by words, full-text in SQLite. By meaning needs a model runtime on the laptop: same steps, one more dependency. We do words today.

> RETRIEVE BEFORE YOU GENERATE

## The industry is building the same thing

Layout: prose

- Databricks, April 2026: "agents cite notebooks from earlier runs that were themselves wrong", and reuse them with more confidence. Their answer, MemCurrent (October 2026), keeps raw traces and distilled lessons. In their own test, success rate went from 22% to 68%.
- Open source you can research: La Roca, Mem0, Letta, Graphiti, LangMem. Traces: Langfuse, OpenTelemetry.
- Your cloud already ships it: AWS AgentCore Memory, Vertex Memory Bank, Azure Foundry.

## Where is the human?

Layout: text

- **Curating:** what gets stored, with what provenance, when to re-validate.
- **Reading:** time, cost, which model is right. Deciding the improvement: another model, another cap, a new skill.
- **Asking:** why did we decide this? Tell me what happened back then when it was decided.

> THE SYSTEM IMPROVES AS IT IS USED. ONLY IF SOMEONE LOOKS.

## Hands on 4 · Ask your system

Layout: hands-on

1. a run from hour 3 still going in its terminal is left going. Open your case. The SQLite holds weeks of runs and conversations from an example team
2. reconstruct it with the query script: what happened, when, who decided, what changed
3. when a run ends, read what it left with your chief: the journal, the worker's report, the reviewer's verdict, the pull request. Then index your own runs and ask: why did we decide this? What happened in the run that failed?
4. the eval: same question with and without retrieval. The chief proposes one improvement

You: Why can't the reviewer merge?
Chief: On 12 March your lead said: "merging is always human". Here is the quote.
You: What went wrong in run 41?
Chief: It looped seven times between worker and reviewer. Since then the cap is two rounds.

# Decided

- Hour 4 analyses what the day piled up: the runs, the decisions and the conversations (decision 8196).
- A run of hour 3 still going when hour 4 starts is left going; when it ends, the group reads what it left before indexing it (decisions 8216 and 8218).
