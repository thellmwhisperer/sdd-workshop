# 009 · Promotions page: edit and delete

## GOAL

Marketing changes or removes a promotion on the page, and the price follows.

## SCOPE

May write: `app/promotions.html`, `app/store.js`, `app/test/promotions-edit.test.html` (new).
May not write: `app/pricing.js` or any other file.

## CONTEXT

Requirement "Marketing edits and deletes promotions" in `openspec/changes/add-shop-promotions/specs/promotions-page/spec.md`. `DOMAIN.md`, decision 1. Missing today: the page only creates and lists (ticket 007). Depends on ticket 007.

## ACCEPTANCE

- 14 · Editing "Black Friday jackets" to 25 %: the jacket is priced 60.00 €.
- 15 · Deleting it: the jacket is priced 80.00 €.

## VERIFY

`sh app/check.sh test` is green, and `app/test/promotions-edit.test.html` prints one `ok` line per scenario 14-15.

## FORBIDDEN

- Do not change the till or the pricing rules.
- Do not touch `openspec/`, `DOMAIN.md`, `tickets/`, `graph/` or `STANDING.md`.
- No new dependency, no Node, no module, no build step.
- Do not weaken, skip or delete an existing test to get green.

## REPORT

Say **done** or **blocked** (and what is missing). List the files you changed, the test
pages you added, the command you ran and its last lines of output.
