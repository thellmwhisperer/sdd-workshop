# 003 · Payment and change

## GOAL

The checkout SHALL take payment by card or cash; for cash it SHALL show the change.

## SCOPE

May write: the code in `app/`, and the new test `app/test/payment.test.html`.
May not write: `graph/`, `openspec/`, `tickets/`, `DOMAIN.md`.

## CONTEXT

The requirement "Payment and change" and its scenarios in
`openspec/changes/checkout-basket-and-returns/specs/checkout/spec.md`. The client and the group's decisions
are in `DOMAIN.md`. Proof it is missing: `ls app/test/` does not list `payment.test.html`.
Depends on: the code of tickets 001 and 002 in `app/`; read it first.

## ACCEPTANCE

- Cash with change: when the total is 55.00 and the customer pays 60.00 in cash, then the change shown is 5.00.

## VERIFY

`cd app && sh check.sh test`, then `sh check.sh typecheck` and `sh check.sh lint`. The
new test `app/test/payment.test.html` checks every line of ACCEPTANCE; it fails before
the change and passes after it, with every other test.

## FORBIDDEN

The other requirements of the change. New dependencies. Weakening or deleting a test.

## REPORT

done or blocked, the files you changed, the names of the tests that ran, and the
`sh check.sh test` output.
