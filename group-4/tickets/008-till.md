# 008 · The till uses marketing's promotions

## GOAL

A promotion saved on the page is applied at the till with no action from the cashier.

## SCOPE

May write: `app/till.html` (new), `app/test/till.test.html` (new).
May not write: `app/pricing.js`, `app/store.js` or any other file.

## CONTEXT

Requirement "The till applies the saved promotions by itself" in `openspec/changes/add-shop-promotions/specs/till-receipt/spec.md`. `DOMAIN.md`, decisions 1 and 2. Missing today: `app/till.html` does not exist. Depends on tickets 005, 006, 007.

## ACCEPTANCE

- 16 · A "second half" promotion on socks saved through `app/store.js`; two socks at the till are charged 6.00 €.

## VERIFY

`sh app/check.sh test` is green, and `app/test/till.test.html` prints `ok` for scenario 16.

## FORBIDDEN

- No cashier override.
- Do not change the promotions page.
- Do not touch `openspec/`, `DOMAIN.md`, `tickets/`, `graph/` or `STANDING.md`.
- No new dependency, no Node, no module, no build step.
- Do not weaken, skip or delete an existing test to get green.

## REPORT

Say **done** or **blocked** (and what is missing). List the files you changed, the test
pages you added, the command you ran and its last lines of output.
