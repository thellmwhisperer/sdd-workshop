## Why

Fil (Claire and Julien Morel, three clothing shops in Lyon, six cashiers) runs on tills that
are twelve years old and no longer supported. Discount stickers are worked out on a
calculator, returns are written on paper notes, and last month 6 of 41 returns were refunded
with the wrong amount. Élodie, the accountant, needs the VAT total of every sale and checks
that stickers come off before VAT. Claire wants a tablet checkout at every counter before the
January sales: a basket with a sticker and a partial return closed in under a minute, and the
screen matching what was really taken at closing time.

## What Changes

- A checkout page in `app/` where the cashier adds products to a basket and sees the total.
- Every price on screen includes VAT, as on the shelf (decision 2).
- A discount sticker comes off the price before VAT, never after.
- The VAT total of every sale is worked out and recorded with the sale, for the accountant.
- Payment by card only (decision 1): no cash, no change, no drawer count.
- Returns with a receipt: refund exactly what was paid for the returned items, sticker
  included, and never more items than were bought.
- Returns without a receipt are allowed (decision 3): the cashier enters the price.
- A basket can hold new products and returned items together; the difference is paid or
  refunded on the card.
- An end-of-day summary: card total taken, card total refunded, and VAT total, so
  the screen can be matched against the card terminal at closing time.

## Capabilities

### New Capabilities
- `checkout`: the basket, its total with VAT included, discount stickers, the VAT of each
  sale, card payment, returns with and without a receipt, and the end-of-day summary.

### Modified Capabilities
- None. `home-page` keeps its requirement: the page title and heading stay "Shop checkout".

## Out of scope

- Cash payments, change and the drawer count (decision 1).
- VAT shown as a separate line on the screen (decision 2).
- A real link to a card terminal, stock, customer accounts, printed receipts.

## Impact

- `app/index.html` and new files under `app/` (JavaScript and CSS loaded by the page).
- New test pages under `app/test/`, run by `sh app/check.sh test`.
- No new dependency: HTML, CSS and JavaScript in the browser only.
