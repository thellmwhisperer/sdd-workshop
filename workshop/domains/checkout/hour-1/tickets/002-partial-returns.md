# 002 · Partial returns

## GOAL

With the receipt of a past sale, the cashier SHALL return some of its lines and the
checkout SHALL show the amount to refund.

## SCOPE

May write: the code in `app/`, and the new test `app/test/returns.test.html`.
May not write: `graph/`, `openspec/`, `tickets/`, `DOMAIN.md`.

## CONTEXT

The requirement "Partial returns" and its scenarios in
`openspec/changes/checkout-basket-and-returns/specs/checkout/spec.md`. The client and the group's decisions
are in `DOMAIN.md`. Proof it is missing: `ls app/test/` does not list `returns.test.html`.
Depends on: the code of ticket 001 in `app/`; read it first.

## ACCEPTANCE

- Return one line: when a receipt has 2 shirts at 20.00 and the customer returns 1 shirt, then the refund is 20.00.

## VERIFY

`cd app && sh check.sh test`, then `sh check.sh typecheck` and `sh check.sh lint`. The
new test `app/test/returns.test.html` checks every line of ACCEPTANCE; it fails before
the change and passes after it, with every other test.

## FORBIDDEN

The other requirements of the change. New dependencies. Weakening or deleting a test.

## REPORT

done or blocked, the files you changed, the names of the tests that ran, and the
`sh check.sh test` output.
