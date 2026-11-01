# The cases of the example team: the rescue

Your own day comes first: index your runs and notes, and rebuild a case of your own. Open
these cases only when your own runs are too few to ask about.

Northbank builds Harbour POS, the tills of a chain of shops. Ines is the lead, Tom an
engineer, Priya product; they work with a chief, a worker, a reviewer and a watcher. Six
weeks of their work, 16 February to 27 March 2026, are in `example-team/`: runs, costs,
the chief's handovers and conversations.

Pick one case. Start with its question, then reconstruct it: what happened, when, who
decided, what changed. Every answer quotes the piece it comes from.

| Case | Start with |
|---|---|
| 1. A rule about who merges | why can't the reviewer merge? |
| 2. The bill that tripled | why was the AI bill so expensive? |
| 3. The run nobody saw | which run was stuck for hours without anyone noticing? |
| 4. Choosing the reviewer | how did we pick the reviewer model? |
| 5. Changing the coding model | why did we change the coding model? |
| 6. The limit of two rounds | where does the limit of two review rounds come from? |
| 7. The discount read the wrong way | did the worker ever apply a discount the wrong way? |

```
sh memory/memory.sh index graph/runs notes chief   your day: runs, notes, your chief
sh memory/memory.sh ask "<question>"     by words, and by meaning with a small model on the laptop
sh memory/memory.sh ask --example "<question>"   these cases, once your own day is kept
sh memory/memory.sh eval "<question>"    the model, without and with what was found
sh memory/memory.sh tables               what is kept, and the questions SQL answers
sh memory/memory.sh sql "<SELECT>"       ask the tables directly
```

Two databases: yours, `group.sqlite`, and the example team's, `example-team.sqlite`. Once
your day is kept, ask, eval and sql read yours; these cases need `--example`. Every
conversation is kept by who said what.
