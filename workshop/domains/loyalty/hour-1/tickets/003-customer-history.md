# 003 · Customer history

## GOAL

The page SHALL show a customer's purchases and point movements, newest first.

## SCOPE

May write: the code in `app/`, and the new test `app/test/history.test.html`.
May not write: `graph/`, `openspec/`, `tickets/`, `DOMAIN.md`.

## CONTEXT

The requirement "Customer history" and its scenarios in
`openspec/changes/loyalty-points/specs/loyalty/spec.md`. The client and the group's decisions
are in `DOMAIN.md`. Proof it is missing: `ls app/test/` does not list `history.test.html`.
Depends on: the code of tickets 001 and 002 in `app/`; read it first.

## ACCEPTANCE

- Two movements: when a customer earned 42 points and later spent 100, then the history shows the spend first, then the earn.

## VERIFY

`cd app && sh check.sh test`, then `sh check.sh typecheck` and `sh check.sh lint`. The
new test `app/test/history.test.html` checks every line of ACCEPTANCE; it fails before
the change and passes after it, with every other test.

## FORBIDDEN

The other requirements of the change. New dependencies. Weakening or deleting a test.

## REPORT

done or blocked, the files you changed, the names of the tests that ran, and the
`sh check.sh test` output.
