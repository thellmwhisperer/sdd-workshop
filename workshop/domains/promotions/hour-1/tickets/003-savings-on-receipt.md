# 003 · Savings on the receipt

## GOAL

The receipt SHALL show the total saved by promotions.

## SCOPE

May write: the code in `app/`, and the new test `app/test/savings.test.html`.
May not write: `graph/`, `openspec/`, `tickets/`, `DOMAIN.md`.

## CONTEXT

The requirement "Savings on the receipt" and its scenarios in
`openspec/changes/weekly-promotions/specs/promotions/spec.md`. The client and the group's decisions
are in `DOMAIN.md`. Proof it is missing: `ls app/test/` does not list `savings.test.html`.
Depends on: the code of tickets 001 and 002 in `app/`; read it first.

## ACCEPTANCE

- One promotion applied: when the second shirt was half price, then the receipt shows 'You saved 10.00'.

## VERIFY

`cd app && sh check.sh test`, then `sh check.sh typecheck` and `sh check.sh lint`. The
new test `app/test/savings.test.html` checks every line of ACCEPTANCE; it fails before
the change and passes after it, with every other test.

## FORBIDDEN

The other requirements of the change. New dependencies. Weakening or deleting a test.

## REPORT

done or blocked, the files you changed, the names of the tests that ran, and the
`sh check.sh test` output.
