# 002 · Spend points

## GOAL

At the till, a customer with at least 100 points SHALL spend them in blocks of 100, each
block taking 5.00 off the total.

## SCOPE

May write: the code in `app/`, and the new test `app/test/spend.test.html`.
May not write: `graph/`, `openspec/`, `tickets/`, `DOMAIN.md`.

## CONTEXT

The requirement "Spend points" and its scenarios in
`openspec/changes/loyalty-points/specs/loyalty/spec.md`. The client and the group's decisions
are in `DOMAIN.md`. Proof it is missing: `ls app/test/` does not list `spend.test.html`.
Depends on: the code of ticket 001 in `app/`; read it first.

## ACCEPTANCE

- One block: when a customer has 130 points and the total is 30.00, then after spending one block the total is 25.00 and 30 points are left.

## VERIFY

`cd app && sh check.sh test`, then `sh check.sh typecheck` and `sh check.sh lint`. The
new test `app/test/spend.test.html` checks every line of ACCEPTANCE; it fails before
the change and passes after it, with every other test.

## FORBIDDEN

The other requirements of the change. New dependencies. Weakening or deleting a test.

## REPORT

done or blocked, the files you changed, the names of the tests that ran, and the
`sh check.sh test` output.
