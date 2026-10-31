# 002 · Second unit at half price

## GOAL

When a basket has two units of a product in a 'second unit at 50 %' promotion, the second
unit SHALL cost half.

## SCOPE

May write: the code in `app/`, and the new test `app/test/second-unit.test.html`.
May not write: `graph/`, `openspec/`, `tickets/`, `DOMAIN.md`.

## CONTEXT

The requirement "Second unit at half price" and its scenarios in
`openspec/changes/weekly-promotions/specs/promotions/spec.md`. The client and the group's decisions
are in `DOMAIN.md`. Proof it is missing: `ls app/test/` does not list `second-unit.test.html`.
Depends on: the code of ticket 001 in `app/`; read it first.

## ACCEPTANCE

- Two shirts: when a shirt costs 20.00, is in the promotion, and the basket has 2, then the basket total is 30.00.

## VERIFY

`cd app && sh check.sh test`, then `sh check.sh typecheck` and `sh check.sh lint`. The
new test `app/test/second-unit.test.html` checks every line of ACCEPTANCE; it fails before
the change and passes after it, with every other test.

## FORBIDDEN

The other requirements of the change. New dependencies. Weakening or deleting a test.

## REPORT

done or blocked, the files you changed, the names of the tests that ran, and the
`sh check.sh test` output.
