## Why

We run three small clothing shops and our tills are old. We want a checkout page on a
tablet at the counter: the cashier adds products to a basket, sees the total and takes
payment. Some products carry a discount sticker. Customers often bring back part of what
they bought, and today that is a mess of paper notes.

Proof: the app in `app/` is a single page with the product name; none of this exists.

## What Changes

- Basket total.
- Partial returns.
- Payment and change.

## Capabilities

### New Capabilities
- `checkout`: shop checkout, as decided by the group in `DOMAIN.md`.

### Modified Capabilities

## Impact

- New code in `app/` only, with one test file per requirement in `app/test/`.
- Not touched: `graph/`, `DOMAIN.md`.
