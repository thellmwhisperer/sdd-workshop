# 001 · Earn points

## GOAL

Each purchase SHALL add 1 point per whole euro spent to the customer, identified by phone
number.

## SCOPE

May write: the code in `app/`, and the new test `app/test/earn.test.html`.
May not write: `graph/`, `openspec/`, `tickets/`, `DOMAIN.md`.

## CONTEXT

The requirement "Earn points" and its scenarios in
`openspec/changes/loyalty-points/specs/loyalty/spec.md`. The client and the group's decisions
are in `DOMAIN.md`. Proof it is missing: `ls app/test/` does not list `earn.test.html`.
Depends on: none, it is the first ticket.

## ACCEPTANCE

- A purchase: when a customer with 0 points buys for 42.80, then the customer has 42 points.

## VERIFY

`cd app && sh check.sh test`, then `sh check.sh typecheck` and `sh check.sh lint`. The
new test `app/test/earn.test.html` checks every line of ACCEPTANCE; it fails before
the change and passes after it, with every other test.

## FORBIDDEN

The other requirements of the change. New dependencies. Weakening or deleting a test.

## REPORT

done or blocked, the files you changed, the names of the tests that ran, and the
`sh check.sh test` output.
