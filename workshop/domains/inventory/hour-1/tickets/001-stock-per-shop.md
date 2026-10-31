# 001 · Stock per shop

## GOAL

The page SHALL show, for a product, size and colour, how many units each shop has.

## SCOPE

May write: the code in `app/`, and the new test `app/test/stock.test.html`.
May not write: `graph/`, `openspec/`, `tickets/`, `DOMAIN.md`.

## CONTEXT

The requirement "Stock per shop" and its scenarios in
`openspec/changes/shop-stock-and-reservations/specs/stock/spec.md`. The client and the group's decisions
are in `DOMAIN.md`. Proof it is missing: `ls app/test/` does not list `stock.test.html`.
Depends on: none, it is the first ticket.

## ACCEPTANCE

- Two shops: when shop A has 3 units and shop B has 0 units of a blue shirt in size M, then the page shows A: 3 and B: 0.

## VERIFY

`cd app && sh check.sh test`, then `sh check.sh typecheck` and `sh check.sh lint`. The
new test `app/test/stock.test.html` checks every line of ACCEPTANCE; it fails before
the change and passes after it, with every other test.

## FORBIDDEN

The other requirements of the change. New dependencies. Weakening or deleting a test.

## REPORT

done or blocked, the files you changed, the names of the tests that ran, and the
`sh check.sh test` output.
