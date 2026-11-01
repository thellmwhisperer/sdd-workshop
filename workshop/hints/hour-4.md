# Hints for hour 4

For the chief only. Give the next hint of the current step, one at a time, in your own
words. Never the answer.

## Step A: keep your day

1. Nothing to install: the tool needs only `sqlite3`. Keep the group's own day:
   `sh memory/memory.sh index graph/runs notes chief`: every agent's conversation in their
   runs, your notes and decisions, and their conversations with you.
2. Every answer says who said it: the group, you, the worker, the reviewer. What an agent
   thought is kept too, and every tool it called, with whether it was denied:
   `sh memory/memory.sh tables` shows the questions SQL answers about them.
3. Too few runs to ask about? Then, and only then, the rescue: the example team's cases in
   `memory/CASES.md`, asked with `sh memory/memory.sh ask --example "<question>"`.

## Step B: rebuild one case of your own

1. Let the group pick a moment of its day: a block of the reviewer, a run that took
   rounds, a decision of hour 1. Ask it with `sh memory/memory.sh ask "<question>"`. It
   searches twice: by words, and by meaning with a small model on the laptop.
2. If by words finds nothing and by meaning finds it, that is the lesson: it was written
   with other words, and the vectors match the meaning. A concrete question works better
   than a vague one.
3. Follow the pieces: each answer names its file and who said it. Open the report or the
   conversation it comes from, and ask the next question from there: who decided, and
   when?

## Step C: the eval

1. `sh memory/memory.sh eval "<question>"`: the same question to the model twice,
   without and with what the search found. Each one costs two model calls.
2. Read both answers aloud. Without retrieval the model should say it does not know; if it
   invents an answer, that is the lesson.
3. With retrieval, check that the answer names the piece it used, and that the piece says
   what the answer says.

## Step D: one improvement

1. Look at what the case shows: time, cost, which model was right, a limit that was
   missing. One improvement only: another model, another limit, a new skill.
2. The chief proposes it, marked `(proposal)`. The group decides whether to keep it.
3. Bring it to the shared discussion: what happened in your case, and what changed after it.
