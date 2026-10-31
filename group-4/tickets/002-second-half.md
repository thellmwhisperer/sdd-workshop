# 002 · Second unit at half price

## GOAL

A "second unit half price" promotion charges every second unit of the same product at half price.

## SCOPE

May write: `app/pricing.js`, `app/test/pricing-second-half.test.html` (new).
May not write: any other file.

## CONTEXT

Requirement "Second unit at half price" in `openspec/changes/add-shop-promotions/specs/promotion-pricing/spec.md`. `DOMAIN.md`, decision 2. Missing today: `Pricing` knows only percent off (ticket 001). Depends on ticket 001.

## ACCEPTANCE

- 3 · Two socks at 4.00 € are charged 6.00 €, saving 2.00 €.
- 4 · Three socks at 4.00 € are charged 10.00 €, saving 2.00 €.

## VERIFY

`sh app/check.sh test` is green, and `app/test/pricing-second-half.test.html` prints one `ok` line per scenario 3-4.

## FORBIDDEN

- Do not build buy 3 pay 2, the best-promotion rule or dates.
- Do not touch `openspec/`, `DOMAIN.md`, `tickets/`, `graph/` or `STANDING.md`.
- No new dependency, no Node, no module, no build step.
- Do not weaken, skip or delete an existing test to get green.

## REPORT

Say **done** or **blocked** (and what is missing). List the files you changed, the test
pages you added, the command you ran and its last lines of output.
