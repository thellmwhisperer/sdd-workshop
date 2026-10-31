## Why

Our marketing team runs promotions every week: second unit at half price, 20 % off
jackets, buy 3 pay 2. Today the cashier has to remember them and apply them by hand, and
gets them wrong. We want promotions defined once and applied at the till.

Proof: the app in `app/` is a single page with the product name; none of this exists.

## What Changes

- Active promotions.
- Second unit at half price.
- Savings on the receipt.

## Capabilities

### New Capabilities
- `promotions`: shop promotions, as decided by the group in `DOMAIN.md`.

### Modified Capabilities

## Impact

- New code in `app/` only, with one test file per requirement in `app/test/`.
- Not touched: `graph/`, `DOMAIN.md`.
