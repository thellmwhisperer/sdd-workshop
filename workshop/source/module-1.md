# Module 1 · The chief of staff

Closing question: What did your chief ask that you had not decided?
Given: `DOMAIN.md` with its open decisions; you
The group decides: The decisions; the ACCEPTANCE numbers; when the backlog is ready
The group builds: The product's change and its tickets, `001` onwards
Rescue: None: a half backlog is still a backlog

## Where the bottleneck is

Layout: text

- A normal Tuesday: one ticket you are implementing. Another one waiting in a PR. A teammate's PR waiting for your review. A spec half written. A bug from production.
- Each one is a context. Every switch costs minutes to load it back, and something gets lost on the way.
- One head holding five threads is a limit. Someone has to hold the threads for you.

> WHO HOLDS THE THREAD?

## The chief of staff, in a nutshell

Layout: text

- **Hands, eyes and ears** for everything that happens inside a domain (project, personal computer, live environments).
- **The domain expert:** it holds the specs, the retrieval and the memory. The closest thing to the top expert in that domain.
- **It stops you:** "this was done; this cannot be done, and here is why".
- It does not code and does not read long logs. It delegates all of that, because its mission is to help you.

> A MODEL THAT THINKS, REASONS AND WORKS WITH YOU

## The pattern

Layout: prose

- You don't have to talk with your individual workers unless necessary. You talk with your chief of staff, and it routes the requests, because it knows who is working on what.
- We don't want agents to guess things. We want deterministic results. What repeats becomes a playbook, and the chief hands it to the next worker.
- Treat them like talented interns. Go one level up and extract what repeats. It needs a feedback loop and eventually a human validation.

## The market already ships the pattern

Layout: numbers

- **Duet** Anthropic: briefs you, alerts you, asks before it acts
- **Dots** OpenAI: keeps things moving, checks in for approval
- **Muse** Meta: give it projects or goals, it works 24/7

## Why a model that thinks, not one that types

Layout: text

- **Its context:** if it coded and read logs it would drown. It saves its context for the thread.
- **The scale:** one domain, a backlog of 50 tickets that keeps growing. The chief runs it and decides. In between, agents to research or debug.
- **When to split:** one chief for the fleet, one for research. Or one per domain.
- You are in two places: requirements in, verification out. The rest is delegated.

> THE ISSUE IS THE CONTEXT

## Key message

Layout: key

> DELEGATE THE MECHANICAL. KEEP THE JUDGMENT.

## Where is the human?

Layout: text

- **Planning with the chief:** it tells the story, you take the decisions, one at a time.
- **Judging the plans:** the tickets it writes, the limits it proposes.
- The domain decisions are yours. The chief writes them down; it does not take them.

> PLANNING AND JUDGING

## Hands on 1 · Your chief

Layout: hands-on

1. open the repo, read AGENTS.md and COS.md
2. your chief tells the client's story from DOMAIN.md and takes the open decisions with you, one at a time
3. it writes the tickets of your domain. You read them and correct them: they are the backlog for the rest of the day

You: Hi. Tell us about our client.
Chief: Your client runs the tills in 200 shops. Before I write anything, one decision: can a cashier cancel a sale after payment?
You: Only with a manager's code.
Chief: Noted. I wrote the change and six tickets. 001 is the smallest: the basket total.

## Two backlogs, one chief

Layout: text

- **Your product:** the client's brief becomes a backlog you decide with your chief. It is ambiguous on purpose: the choices are yours.
- **Your machine:** the graph that closes that backlog. You build it from hour 2, the node first, then the path, and it runs the same tickets.
- First the backlog. Then the machine. Then the machine works the backlog.

> THIS HOUR: THE BACKLOG. FROM HOUR 2: THE MACHINE

# Decided

- Hour 1 only writes tickets and takes decisions: no code is built in this hour (decision 8196).
- The film ends with the first decision of the group, never with "tell me when you are ready" (Javi, 30 October, rehearsal of group 4).
