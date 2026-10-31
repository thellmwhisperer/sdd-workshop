# 002 · Reserve in another shop

## GOAL

A staff member SHALL reserve units of a product in another shop for a customer; the
reserved units SHALL stop counting as available.

## SCOPE

May write: the code in `app/`, and the new test `app/test/reserve.test.html`.
May not write: `graph/`, `openspec/`, `tickets/`, `DOMAIN.md`.

## CONTEXT

The requirement "Reserve in another shop" and its scenarios in
`openspec/changes/shop-stock-and-reservations/specs/stock/spec.md`. The client and the group's decisions
are in `DOMAIN.md`. Proof it is missing: `ls app/test/` does not list `reserve.test.html`.
Depends on: the code of ticket 001 in `app/`; read it first.

## ACCEPTANCE

- Reserve one: when shop A has 3 units and staff reserve 1 for a customer, then shop A shows 2 available and 1 reserved.

## VERIFY

`cd app && sh check.sh test`, then `sh check.sh typecheck` and `sh check.sh lint`. The
new test `app/test/reserve.test.html` checks every line of ACCEPTANCE; it fails before
the change and passes after it, with every other test.

## FORBIDDEN

The other requirements of the change. New dependencies. Weakening or deleting a test.

## REPORT

done or blocked, the files you changed, the names of the tests that ran, and the
`sh check.sh test` output.
