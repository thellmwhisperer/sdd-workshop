# 005 · Only promotions in their dates

## GOAL

A promotion applies only from its start date to its end date, both included, so Black Friday ends when marketing said.

## SCOPE

May write: `app/pricing.js`, `app/test/pricing-dates.test.html` (new).
May not write: any other file.

## CONTEXT

Requirement "Only promotions in their dates" in `openspec/changes/add-shop-promotions/specs/promotion-pricing/spec.md`. `openspec/changes/add-shop-promotions/design.md`: dates as `YYYY-MM-DD`, both ends included. Missing today: `Pricing` ignores dates. Depends on ticket 001.

## ACCEPTANCE

- 9 · A 20 % jacket promotion that ended 2026-10-25, priced on 2026-10-26: the jacket is 80.00 €.
- 10 · The same promotion ending 2026-11-01, priced on 2026-11-01: the jacket is 64.00 €.

## VERIFY

`sh app/check.sh test` is green, and `app/test/pricing-dates.test.html` prints one `ok` line per scenario 9-10.

## FORBIDDEN

- Do not build the receipt or any page.
- Do not touch `openspec/`, `DOMAIN.md`, `tickets/`, `graph/` or `STANDING.md`.
- No new dependency, no Node, no module, no build step.
- Do not weaken, skip or delete an existing test to get green.

## REPORT

Say **done** or **blocked** (and what is missing). List the files you changed, the test
pages you added, the command you ran and its last lines of output.
