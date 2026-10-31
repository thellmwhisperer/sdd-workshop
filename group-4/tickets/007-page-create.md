# 007 · Promotions page: create and list

## GOAL

Marketing creates promotions on a page and sees them listed, without asking IT; broken promotions are refused.

## SCOPE

May write: `app/promotions.html` (new), `app/store.js` (new), `app/test/promotions-page.test.html` (new).
May not write: `app/pricing.js` or any other file.

## CONTEXT

Requirements "Marketing creates and lists promotions" and "The page refuses a broken promotion" in `openspec/changes/add-shop-promotions/specs/promotions-page/spec.md`. `DOMAIN.md`, decision 1: marketing uses a page. `openspec/changes/add-shop-promotions/design.md`: promotions in `localStorage` under one key (proposal). Missing today: `app/promotions.html` does not exist. Depends on ticket 001 (the promotion's fields).

## ACCEPTANCE

- 11 · Creating "Black Friday jackets", 20 % off jackets, lists it, and it is still listed after a reload.
- 12 · 120 % is refused with a message, and nothing is saved.
- 13 · An end date before the start date is refused with a message, and nothing is saved.

## VERIFY

`sh app/check.sh test` is green, and `app/test/promotions-page.test.html` prints one `ok` line per scenario 11-13.

## FORBIDDEN

- Do not build edit or delete (ticket 009) or the till.
- Do not touch `openspec/`, `DOMAIN.md`, `tickets/`, `graph/` or `STANDING.md`.
- No new dependency, no Node, no module, no build step.
- Do not weaken, skip or delete an existing test to get green.

## REPORT

Say **done** or **blocked** (and what is missing). List the files you changed, the test
pages you added, the command you ran and its last lines of output.
