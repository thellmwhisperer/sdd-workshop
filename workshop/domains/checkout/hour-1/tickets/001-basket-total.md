# 001 · Basket total

## GOAL

The checkout SHALL keep a basket of lines (product, unit price with VAT, quantity,
optional discount in percent) and show its total.

## SCOPE

May write: the code in `app/`, and the new test `app/test/basket.test.html`.
May not write: `graph/`, `openspec/`, `tickets/`, `DOMAIN.md`.

## CONTEXT

The requirement "Basket total" and its scenarios in
`openspec/changes/checkout-basket-and-returns/specs/checkout/spec.md`. The client and the group's decisions
are in `DOMAIN.md`. Proof it is missing: `ls app/test/` does not list `basket.test.html`.
Depends on: none, it is the first ticket.

## ACCEPTANCE

- Two lines: when the basket has 2 shirts at 20.00 and 1 belt at 15.00, then the total is 55.00.

## VERIFY

`cd app && sh check.sh test`, then `sh check.sh typecheck` and `sh check.sh lint`. The
new test `app/test/basket.test.html` checks every line of ACCEPTANCE; it fails before
the change and passes after it, with every other test.

## FORBIDDEN

The other requirements of the change. New dependencies. Weakening or deleting a test.

## REPORT

done or blocked, the files you changed, the names of the tests that ran, and the
`sh check.sh test` output.
