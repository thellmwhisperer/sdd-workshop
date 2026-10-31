# How an agent step reports

Every agent step ends by writing its `report.md` in Markdown: four headings, in this
order, each `## ` at the start of its own line, a blank line between sections, lists with a
dash, command output indented four spaces. The node checks that the four headings are
there; a report without one of them is red.

```markdown
## Ticket
tickets/001-basket-total.md: done

## Changed
- app/basket.js
- app/test/basket.test.html

## Checked
`sh app/check.sh test`:
    ok the basket adds two lines
    ok the total is 23.50 for 12.00 and 11.50
`sh app/check.sh typecheck` and `sh app/check.sh lint`: no output, exit 0

## Not done
nothing
```

What goes under each heading:

- `## Ticket`: the ticket you were given, and in a few words whether it is done or blocked.
- `## Changed`: every file you changed or created, one per line with a dash, or `nothing`.
- `## Checked`: the commands you ran to prove it, and what they printed (the last lines).
- `## Not done`: what the ticket asked and you did not do, and why; or `nothing`.

Reviewers only, one more line at the end, after a blank line, one of these two:

```markdown
Verdict: pass
```

```markdown
Verdict: block
The ticket asks for a test of a zero price and there is none.
```

After `Verdict: block`, the next line says why, in one sentence: the scenario, the line of
the ticket or the rule it breaks. The node reads it: `block` is red, and the path goes back
to the worker.
