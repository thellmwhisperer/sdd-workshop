# Hints for hour 4

For the chief only. Give the next hint of the current step, one at a time, in your own
words. Never the answer.

## Step A: open your case

1. Nothing to install: the tool needs only `sqlite3`. Read `memory/CASES.md` with the group
   and let them pick one case.
2. Ask its starting question with `sh memory/memory.sh ask "<question>"`. It searches
   twice: by words, and by meaning with a small model on the laptop.
3. If by words finds nothing and by meaning finds it, that is the lesson: the team wrote
   it with other words, and the vectors match the meaning. A concrete question works
   better than a vague one.

## Step B: reconstruct it, then your own runs

1. Follow the pieces: each answer names its file. Open the conversation or the handover
   it comes from, and ask the next question from there: who decided, and when?
2. Index the group's own runs: `sh memory/memory.sh index graph/runs notes`. They go to
   their own index, `group.sqlite`, next to the example team's, so neither buries the
   other: ask answers from each one apart.
3. Ask about them: why did we decide this? What happened in the run that failed?
4. Each piece says who speaks: User is the graph's brief, Copilot is the agent. Answers
   leave out Copilot's raw events and the tool turns (a file the agent read, a command it
   ran). When ask says left-out pieces also matched, `sh memory/memory.sh ask --raw
   "<question>"` shows them.

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
