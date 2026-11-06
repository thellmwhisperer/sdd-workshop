# 003 · VAT total of a sale

## GOAL
Every basket knows its VAT total, the sum of the VAT of its lines, so the accountant gets
it with each sale. The cashier's screen keeps showing prices with VAT included only.

## SCOPE
May write: `app/checkout.js`, `app/test/vat.test.html` (new).
May not write: anything else, in particular the page, `app/test/check.js`, `app/check.sh`
and the other tests.

## CONTEXT
- OpenSpec: `spec.md` of the change `add-shop-checkout`, requirement 3.
- Decisions: VAT 20 %; each line rounded to the nearest cent, half up; VAT recorded but not
  shown on the screen (group 1).
- The rule: without a sticker, VAT = price − round(price / 1.2); with a sticker, the VAT of
  ticket 002 (reduced × 0.2, rounded).
- The shape to build: `Checkout.unitVat(product)` returns the VAT of one unit in cents;
  each line gets `vat` (quantity × unit VAT); `Checkout.vat(basket)` returns the sum.
- Missing today: no VAT anywhere in `app/checkout.js`.
- Depends on: tickets 001 and 002.

## ACCEPTANCE
- 3.1 A shirt at 60.00 and a shirt at 60.00 with a 30 % sticker: total 102.00, VAT total 17.00.
- 3.2 A scarf at 25.00: VAT total 4.17.

## VERIFY
From the group folder: `sh app/check.sh test` and `sh app/check.sh lint`, both exit 0, the
earlier tests still green. The test it adds: `app/test/vat.test.html`, one `check()` per
ACCEPTANCE line, named by its number, on `Checkout.money` of the total and of
`Checkout.vat`.

## FORBIDDEN
- Showing VAT on the page.
- Payment, returns, requirements 4 to 8.
- Any dependency, module or Node.
- Changing, skipping or weakening any existing test.

## REPORT
Done or blocked. The files written. The commands run and their full output. Anything the
spec did not say that you needed.
