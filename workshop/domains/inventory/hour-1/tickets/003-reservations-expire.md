# 003 · Reservations expire

## GOAL

A reservation SHALL expire after 48 hours and its units SHALL count as available again.

## SCOPE

May write: the code in `app/`, and the new test `app/test/expire.test.html`.
May not write: `graph/`, `openspec/`, `tickets/`, `DOMAIN.md`.

## CONTEXT

The requirement "Reservations expire" and its scenarios in
`openspec/changes/shop-stock-and-reservations/specs/stock/spec.md`. The client and the group's decisions
are in `DOMAIN.md`. Proof it is missing: `ls app/test/` does not list `expire.test.html`.
Depends on: the code of tickets 001 and 002 in `app/`; read it first.

## ACCEPTANCE

- After two days: when a reservation of 1 unit was made 49 hours ago, then the unit counts as available again.

## VERIFY

`cd app && sh check.sh test`, then `sh check.sh typecheck` and `sh check.sh lint`. The
new test `app/test/expire.test.html` checks every line of ACCEPTANCE; it fails before
the change and passes after it, with every other test.

## FORBIDDEN

The other requirements of the change. New dependencies. Weakening or deleting a test.

## REPORT

done or blocked, the files you changed, the names of the tests that ran, and the
`sh check.sh test` output.
