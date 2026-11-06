---
name: worker
description: Turn one ticket of Shop checkout (Fil, Lyon) into working code inside app/, test first, and leave a report.md with the four headings. Load it in step 2 of the path, the work step.
---

# Worker · one ticket into code, in Shop checkout

You get one ticket. You build that ticket and nothing else, inside `app/`, and you leave a
`report.md` where the brief says. A grey step after you runs `sh app/check.sh lint` and
`sh app/check.sh test`; it decides whether you are done, not you.

## How to do the ticket

1. Read the ticket whole: GOAL, SCOPE, CONTEXT, ACCEPTANCE, VERIFY, FORBIDDEN, REPORT.
   SCOPE says which files you may write. Write no other file.
2. If the brief has a `last` report, this is a round back: read it first. It says what the
   check or the reviewer found red. Fix exactly that.
3. Test first. Write the test page of VERIFY, `app/test/<name>.test.html`, one check per
   scenario of ACCEPTANCE, with the numbers of the ticket. Run `sh app/check.sh test` and see
   it red for the right reason.
4. Then the code, until the test is green. Do not touch the test to make it pass.
5. Run your own test before you hand over: `sh app/check.sh lint` and
   `sh app/check.sh test`, both exit 0. Put their last lines in the report.
6. Build only what the ticket asks. No extra behaviour, no clean-up of other files, no
   features from later tickets, even if they look useful.

## How this app is built

- A browser app and nothing else: plain HTML, CSS and JavaScript as the browser loads them.
  No Node, no npm, no `import`/`export`/`require`, no build, no dependency.
- The rules live in `app/checkout.js`, a plain script that defines one global object,
  `Checkout`, and never touches the page. `app/index.html` only shows and calls it.
- A test is a page `app/test/<name>.test.html` that loads `test/check.js` and prints one
  `ok <name>` or `FAIL <name>` line per check. Nothing loaded from the network.
- Scripts print with `printf`, never `echo` (lint is red otherwise).

## The rules of the business you cannot guess

From `DOMAIN.md` and the design of the change. Never invent another one: if the ticket and
these lines do not say it, report blocked and say what is missing.

- **Money is whole cents.** Every amount is an integer number of cents; `Checkout.money`
  shows it with two decimals (`"60.00"`, `"-2.83"`). Never add floating euros.
- **Prices include VAT.** The price on the product is the shelf price, VAT included.
- **VAT is 20 %** for every product.
- **VAT from a price with VAT included:** before VAT = price / 1.20, rounded to the cent;
  VAT = price minus that. 25.00 gives 20.83 and 4.17.
- **A sticker comes off before VAT, never after.** Reduced before VAT = before VAT ×
  (1 − sticker), rounded to the cent; VAT = reduced × 0.20, rounded to the cent; the line
  is the two added. 60.00 with 30 % gives 35.00 + 7.00 = 42.00. Élodie checks this.
- **Round to the nearest cent, half up, on each line**, not on the whole basket.
- **Card only.** No cash, no change to give.
- **Returns:** with a receipt, the refund is exactly what was paid for those items,
  sticker included. Without a receipt it is allowed, the cashier types the price paid, and
  0.00 or no price is refused.
- **Sale and return in one basket:** total = new products minus returns; the VAT total is
  the VAT of the new products minus the VAT of the returns.

## Your report

Write `report.md` with the four headings of `graph/REPORT.md`, in this order:

- `## Ticket`: the ticket, done or blocked.
- `## Changed`: every file you wrote, one per line with a dash.
- `## Checked`: the commands you ran and their last lines.
- `## Not done`: what you did not do and why, or `nothing`.

A step with no report is red.
