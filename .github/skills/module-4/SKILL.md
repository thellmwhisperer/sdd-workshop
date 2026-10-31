---
name: module-4
description: For the chief of staff. What Javier taught in module 4, memory that improves the system, and how hands on 4 uses it. Load it in hour 4, and whenever the group asks about agent memory, the four types of memory, episodic memory, RAG, retrieval, vectors, the corpus, evals, or how the system improves.
---

# Module 4 · Memory that improves the system

You are Javier's assistant at this table. The group has just heard this talk. Use it to
answer their questions with his words, and tie every answer to what they are doing now.

<!-- source:module begin: written by sh workshop/source/render.sh from workshop/source/; edit the source, never this block -->
## What Javier said, slide by slide

These are his slides, in his order, as the decks show them. Quote them; never add a slide
or a line he did not say.

### How do you remember?

- **Right now:** what you are holding in your head this minute.
- **Facts:** what you know is true, like the discount going before VAT.
- **Skills:** how to do things, like writing backwards on glass.
- **Experience:** the three hours lost on the wrong Kubernetes cluster.

Key line: **A WELL-DESIGNED AGENT NEEDS THE SAME FOUR**

### Four types of agent memory (CoALA, Princeton)

- Working: the context window. Like RAM: fast, volatile, with a ceiling
- Semantic: what it knows in general. In practice, markdown files such as AGENTS.md
- Procedural: how to do things. SKILL.md, loaded only when the task matches
- Episodic: what happened before and what it learned. The hardest to get right
- Thermostat: working memory. Password-reset bot: plus a skill. Coding agent: all four

### The four memories in the graph you built

- **Working:** the worker's clean window, one per ticket
- **Semantic:** AGENTS.md and DOMAIN.md
- **Procedural:** the skills from module 3
- **Episodic:** the SQLite with your runs. This module

Memory is what separates a chatbot from an agent

### Episodic memory: the hardest one

- Why the conversations: to recall past conversations and their context, the human's and the agent's. A decision is backed by a human's word, not by a metric. When something goes wrong you rebuild the timeline step by step: what the chief of staff said, what the agent answered.
- What you do with it: run times, cost, which model is better, repeated patterns that become a skill. The system improves as it is used. Distil on top of the source, never instead of it.

### RAG or memory?

- **RAG** reads what a person wrote on purpose: specs, docs, tickets.
- **Memory** reads what the agent lived: runs, verdicts, what it fixed and how.
- Your SQLite holds both. The specs and tickets are RAG. The runs and verdicts are memory.

Key line: **WHAT YOU WROTE. WHAT IT LIVED.**

### Key message

Key line: **EVERY RUN IS DATA. THE SYSTEM GETS BETTER ONLY IF YOU KEEP IT AND LOOK AT IT.**

### What teams running this can see in their data

- **4 h** A run waited 4 h in review. Nobody was told
- **86%** One reviewer model was right in 86% of 32 cases
- **0 of 6** One worker model: 6 PRs, none clean through the gate

### Your corpus: what you and your system wrote

- The chief's tickets
- Worker reports and reviewer verdicts
- Time and cost per step
- The chief's handover
- Conversations: you with the chief, the chief with its agents

### Key message

Key line: **NOT A MONITORING DASHBOARD. EVERY DECISION IS BACKED BY A HUMAN'S WORD.**

### RAG in a nutshell

- **Index:** cut what the system produced into pieces and store them.
- **Retrieve:** find the pieces that answer your question.
- **Generate:** the model answers with those pieces in its context.
- In this module: each question searched two ways, by words (full-text in SQLite) and by meaning (vectors from a 23 MB model that runs on your laptop). Same steps at any size.

Key line: **RETRIEVE BEFORE YOU GENERATE**

### The industry is building the same thing

- Databricks, April 2026: "agents cite notebooks from earlier runs that were themselves wrong", and reuse them with more confidence. Their answer, MemCurrent (October 2026), keeps raw traces and distilled lessons. In their own test, success rate went from 22% to 68%.
- Open source you can research: La Roca, Mem0, Letta, Graphiti, LangMem. Traces: Langfuse, OpenTelemetry.
- Your cloud already ships it: AWS AgentCore Memory, Vertex Memory Bank, Azure Foundry.

### Where is the human?

- **Curating:** what gets stored, with what provenance, when to re-validate.
- **Reading:** time, cost, which model is right. Deciding the improvement: another model, another cap, a new skill.
- **Asking:** why did we decide this? Tell me what happened back then when it was decided.

Key line: **THE SYSTEM IMPROVES AS IT IS USED. ONLY IF SOMEONE LOOKS.**

### Hands on 4 · Ask your system

1. a run from hour 3 still going in its terminal is left going. Open your case. The SQLite holds weeks of runs and conversations from an example team
2. reconstruct it with the query script: what happened, when, who decided, what changed
3. when a run ends, read what it left with your chief: the journal, the worker's report, the reviewer's verdict, the pull request. Then index your own runs and ask: why did we decide this? What happened in the run that failed?
4. the eval: same question with and without retrieval. The chief proposes one improvement

The example on the slide:

- You: Why can't the reviewer merge?
- Chief: On 12 March your lead said: "merging is always human". Here is the quote.
- You: What went wrong in run 41?
- Chief: It looped seven times between worker and reviewer. Since then the cap is two rounds.

## Javier's closing question

"What happened in your case, and what changed after it?"

Javier asks it in the room, after the hands on. You never ask it.

## Closed decisions

Javier closed these. Follow them; never reopen them, and never ask the group about them again.

- Hour 4 analyses what the day piled up: the runs, the decisions and the conversations (decision 8196).
- A run of hour 3 still going when hour 4 starts is left going; when it ends, the group reads what it left before indexing it (decisions 8216 and 8218).
<!-- source:module end -->

## The hands on, and where each step lives

| Step in the deck | In the group's folder |
|---|---|
| Open your case: weeks of runs and conversations from an example team | `memory/CASES.md`, `example-team/`; `sh memory/memory.sh ask "<question>"` |
| Reconstruct it: what happened, when, who decided, what changed | Every answer quotes the piece it comes from |
| Index your own runs and ask about them | `sh memory/memory.sh index graph/runs notes` |
| The eval, with and without retrieval; the chief proposes one improvement | `sh memory/memory.sh eval "<question>"` |

The example in the deck: "Why can't the reviewer merge?" On 12 March the lead said
"merging is always human", with the quote. "What went wrong in run 41?" Seven rounds
between worker and reviewer; since then the cap is two.

## Tie the talk to the work

- The group's own notes (`notes/`, one per hour, written by you) are episodic memory: the
  decisions of the day backed by their words. Index them with their runs.
- Ask shows two searches. By words finds the pieces that hold the question's words; when
  it finds nothing, the team wrote it with other words. By meaning (vectors, MiniLM on
  the laptop) finds the pieces that mean the same, with other words; its score goes from
  0, nothing in common, to 1, the same meaning. Read both with the group: that difference
  is the lesson. A concrete question works better than a vague one.
- In the eval, the answer without retrieval is the model alone; with retrieval it quotes
  the source. That is "retrieve before you generate".
- The improvement you propose comes from what they read: another model, another cap, a new
  skill. Mark it `(proposal)`; the group decides.

## Questions they may ask

- **Is this a dashboard?** No: every decision is backed by a human's word, and you can read
  it.
- **Why keep the raw conversations if we have a summary?** Distil on top of the source,
  never instead of it: a summary can be wrong, the source can be checked.
- **Do we need a vector database?** Not here: a SQLite file on the laptop holds the
  pieces and their vectors, and a 23 MB model on the laptop makes them. The steps are the
  same at any size; a vector database is for millions of pieces.
