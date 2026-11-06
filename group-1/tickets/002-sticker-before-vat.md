# 002 · Discount sticker before VAT

## GOAL
A product with a discount sticker costs what the accountant expects: the sticker comes off
the price before VAT, never off the shelf price, so the shops stop being a cent off.

## SCOPE
May write: `app/checkout.js`, `app/test/sticker.test.html` (new).
May not write: anything else, in particular the page, `app/test/check.js`, `app/check.sh`
and the other tests.

## CONTEXT
- OpenSpec: `spec.md` of the change `add-shop-checkout`, requirement 2.
- Decisions: VAT 20 % on every product; each line rounded to the nearest cent, half up;
  a sticker is one percentage set on the product (`design.md`, all by group 1).
- The rule: price before VAT = price / 1.2, rounded to the cent; reduced = that × (1 −
  sticker / 100), rounded to the cent; VAT = reduced × 0.2, rounded to the cent; the line
  price is reduced + VAT.
- The shape to build: a product may carry `sticker`, a percentage (`30` means 30 %).
  `Checkout.linePrice(product)` returns the unit price in cents. `Checkout.add` uses it for
  the line's `amount`.
- Missing today: `Checkout` from ticket 001 has no sticker; a product's price is its shelf
  price.
- Depends on: ticket 001.

## ACCEPTANCE
- 2.1 A shirt at 60.00 with a 30 % sticker: the line reads 42.00.
- 2.2 A jumper at 39.90 with a 15 % sticker: the line reads 33.91, not 33.92.
- 2.3 A shirt at 60.00 with no sticker: the line reads 60.00.

## VERIFY
From the group folder: `sh app/check.sh test` and `sh app/check.sh lint`, both exit 0, the
tests of ticket 001 still green. The test it adds: `app/test/sticker.test.html`, one
`check()` per ACCEPTANCE line, named by its number, on `Checkout.money` of the line amount
after `Checkout.add`.

## FORBIDDEN
- The VAT total of a sale, payment, returns, requirements 3 to 8.
- A sticker typed by the cashier, or more than one sticker per product.
- Touching the page; any dependency, module or Node.
- Changing, skipping or weakening any existing test.

## REPORT
Done or blocked. The files written. The commands run and their full output. Anything the
spec did not say that you needed.
