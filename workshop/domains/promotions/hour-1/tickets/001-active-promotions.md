# 001 · Active promotions

## GOAL

The page SHALL list the promotions active on a given date, with their start and end dates.

## SCOPE

May write: the code in `app/`, and the new test `app/test/promotions.test.html`.
May not write: `graph/`, `openspec/`, `tickets/`, `DOMAIN.md`.

## CONTEXT

The requirement "Active promotions" and its scenarios in
`openspec/changes/weekly-promotions/specs/promotions/spec.md`. The client and the group's decisions
are in `DOMAIN.md`. Proof it is missing: `ls app/test/` does not list `promotions.test.html`.
Depends on: none, it is the first ticket.

## ACCEPTANCE

- One active, one past: when one promotion runs this week and another ended last week, then only this week's promotion is listed.

## VERIFY

`cd app && sh check.sh test`, then `sh check.sh typecheck` and `sh check.sh lint`. The
new test `app/test/promotions.test.html` checks every line of ACCEPTANCE; it fails before
the change and passes after it, with every other test.

## FORBIDDEN

The other requirements of the change. New dependencies. Weakening or deleting a test.

## REPORT

done or blocked, the files you changed, the names of the tests that ran, and the
`sh check.sh test` output.
