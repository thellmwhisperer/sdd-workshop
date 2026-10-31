# 001 · Percent off a category

## GOAL

A product in a category with a percent-off promotion is charged that percent less, so Brisa's tills stop charging jackets at the wrong price.

## SCOPE

May write: `app/pricing.js` (new), `app/test/pricing-percent.test.html` (new).
May not write: any other file.

## CONTEXT

Requirement "Percent off a category" in `openspec/changes/add-shop-promotions/specs/promotion-pricing/spec.md`. `DOMAIN.md`, decision 2: promotions apply automatically. `openspec/changes/add-shop-promotions/design.md`: one global `Pricing` in `app/pricing.js`, money in whole cents, a function taking a basket, the promotions and a date that returns each line's price, the total and the saving. Missing today: `app/pricing.js` does not exist. Depends on nothing.

## ACCEPTANCE

- 1 · Jacket 80.00 € with 20 % off jackets is charged 64.00 €, saving 16.00 €.
- 2 · Cap 15.00 € (not a jacket) with the same promotion is charged 15.00 €, saving 0.

## VERIFY

`sh app/check.sh test` is green, and the new page `app/test/pricing-percent.test.html` prints one `ok` line per scenario 1-2.

## FORBIDDEN

- Do not build the other promotion kinds, the best-promotion rule or dates: they are tickets 002 to 005.
- Do not touch `openspec/`, `DOMAIN.md`, `tickets/`, `graph/` or `STANDING.md`.
- No new dependency, no Node, no module, no build step.
- Do not weaken, skip or delete an existing test to get green.

## REPORT

Say **done** or **blocked** (and what is missing). List the files you changed, the test
pages you added, the command you ran and its last lines of output.
