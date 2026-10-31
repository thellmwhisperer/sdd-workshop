# 004 · One promotion per product, the best one

## GOAL

When several promotions apply to a product, the customer gets only the one that saves the most; promotions never stack. This is the jacket that got 20 % off twice.

## SCOPE

May write: `app/pricing.js`, `app/test/pricing-best.test.html` (new).
May not write: any other file.

## CONTEXT

Requirement "One promotion per product, the best for the customer" in `openspec/changes/add-shop-promotions/specs/promotion-pricing/spec.md`. Client rule in `DOMAIN.md`: never stack, best one per product; decision 2. `openspec/changes/add-shop-promotions/design.md`: equal savings, the first saved wins. Missing today: nothing chooses between promotions. Depends on tickets 001-003.

## ACCEPTANCE

- 7 · Jacket 80.00 € with 20 % and 10 % both active is charged 64.00 €; the saving is 16.00 €, never 23.20 €.
- 8 · Three socks at 4.00 € with "second half" and "buy 3 pay 2" both active are charged 8.00 €, saving 4.00 €.

## VERIFY

`sh app/check.sh test` is green, and `app/test/pricing-best.test.html` prints one `ok` line per scenario 7-8.

## FORBIDDEN

- Do not build dates, the receipt or any page.
- Do not touch `openspec/`, `DOMAIN.md`, `tickets/`, `graph/` or `STANDING.md`.
- No new dependency, no Node, no module, no build step.
- Do not weaken, skip or delete an existing test to get green.

## REPORT

Say **done** or **blocked** (and what is missing). List the files you changed, the test
pages you added, the command you ran and its last lines of output.
