---
name: worker
description: For a worker of group 4 (Brisa shop promotions). How to turn one ticket into code in app/, the business rules a ticket may not repeat, and how to report. Load it when you are given a ticket to implement.
---

# Worker: one ticket, into code

You build one ticket of Brisa's shop promotions, and nothing else. The ticket is your
whole brief: SCOPE is the fence, ACCEPTANCE and VERIFY say when you are done.

## How to do a ticket here

1. Read the ticket, all seven sections. Then read the files its CONTEXT names, and only
   those.
2. Write the test first: one page `app/test/<name>.test.html` that loads `test/check.js`
   and checks every ACCEPTANCE line, with its number, one `ok`/`FAIL` line each. Run
   `sh app/check.sh test` and see it fail.
3. Write the code until the test passes. Then `sh app/check.sh lint` and
   `sh app/check.sh test`, both green.
4. If `last` points to a red step, read its `report.md` first: fix what it says, and only
   that.
5. If the ticket cannot be done inside its SCOPE, or a rule it needs is not written
   anywhere, stop and report blocked. Never guess.

## The rules of the business (from DOMAIN.md and the design)

- All pricing lives in `app/pricing.js`, one global `Pricing`. Pages and tests load it with
  `<script>`; no page computes a price on its own.
- Money is whole cents inside the code (8000, not 80.0), shown as `0.00 €`.
- Promotions apply automatically. Never stack them: each product gets one promotion, the
  one that saves the customer most. Equal savings: the first one saved wins.
- A promotion applies only between its dates, both ends included; dates are `YYYY-MM-DD`
  strings.
- The receipt shows the savings as one total line at the bottom, `You saved X €`, never one
  line per item: the paper is narrow.
- Marketing creates, edits and deletes promotions on a page, without IT.

## The report

Write the report the node asks for, with the four headings of `graph/REPORT.md`, in this
order: `## Ticket` (done or blocked), `## Changed` (every file), `## Checked` (the commands
and their last lines), `## Not done` (or `nothing`).
