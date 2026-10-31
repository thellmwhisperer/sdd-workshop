# 006 · Receipt with one savings line

## GOAL

The receipt ends with one line, "You saved X €", when the customer saved something, and with no such line otherwise.

## SCOPE

May write: `app/receipt.js` (new), `app/products.js` (new), `app/test/receipt.test.html` (new).
May not write: `app/pricing.js` or any other file.

## CONTEXT

Requirement "One savings line on the receipt" in `openspec/changes/add-shop-promotions/specs/till-receipt/spec.md`. `DOMAIN.md`, decision 3: a single total line "You saved X €". `openspec/changes/add-shop-promotions/design.md`: products jacket 80.00 €, socks 4.00 €, T-shirt 10.00 €, cap 15.00 € in `app/products.js` (proposal). Missing today: there is no receipt. Depends on tickets 001-005.

## ACCEPTANCE

- 17 · Jacket (20 % off jackets) and two socks (second half): total 70.00 €, last line "You saved 18.00 €", no other savings line.
- 18 · One cap with no promotion: no "You saved" line.

## VERIFY

`sh app/check.sh test` is green, and `app/test/receipt.test.html` prints one `ok` line per scenario 17-18.

## FORBIDDEN

- No savings line per item.
- Do not build the promotions page or the till page.
- Do not touch `openspec/`, `DOMAIN.md`, `tickets/`, `graph/` or `STANDING.md`.
- No new dependency, no Node, no module, no build step.
- Do not weaken, skip or delete an existing test to get green.

## REPORT

Say **done** or **blocked** (and what is missing). List the files you changed, the test
pages you added, the command you ran and its last lines of output.
