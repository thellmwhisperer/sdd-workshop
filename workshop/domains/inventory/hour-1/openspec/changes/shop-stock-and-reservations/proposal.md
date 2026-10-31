## Why

We have four shops in the same city. Each shop keeps its own stock in a spreadsheet. When
a customer wants a size that the shop does not have, the staff phone the other shops one
by one. We want one page where staff see the stock of every shop and can reserve units in
another shop for a customer.

Proof: the app in `app/` is a single page with the product name; none of this exists.

## What Changes

- Stock per shop.
- Reserve in another shop.
- Reservations expire.

## Capabilities

### New Capabilities
- `stock`: stock across shops, as decided by the group in `DOMAIN.md`.

### Modified Capabilities

## Impact

- New code in `app/` only, with one test file per requirement in `app/test/`.
- Not touched: `graph/`, `DOMAIN.md`.
