# 003 · Buy 3 pay 2

## GOAL

A "buy 3 pay 2" promotion makes every third unit of the same product free.

## SCOPE

May write: `app/pricing.js`, `app/test/pricing-three-for-two.test.html` (new).
May not write: any other file.

## CONTEXT

Requirement "Buy 3 pay 2" in `openspec/changes/add-shop-promotions/specs/promotion-pricing/spec.md`. `DOMAIN.md`, decision 2. Missing today: `Pricing` has no such kind. Depends on ticket 001.

## ACCEPTANCE

- 5 · Three T-shirts at 10.00 € are charged 20.00 €, saving 10.00 €.
- 6 · Two T-shirts at 10.00 € are charged 20.00 €, saving 0.

## VERIFY

`sh app/check.sh test` is green, and `app/test/pricing-three-for-two.test.html` prints one `ok` line per scenario 5-6.

## FORBIDDEN

- Do not build the best-promotion rule or dates.
- Do not touch `openspec/`, `DOMAIN.md`, `tickets/`, `graph/` or `STANDING.md`.
- No new dependency, no Node, no module, no build step.
- Do not weaken, skip or delete an existing test to get green.

## REPORT

Say **done** or **blocked** (and what is missing). List the files you changed, the test
pages you added, the command you ran and its last lines of output.
