# 004 · Return without a receipt

## GOAL
A customer without a receipt is not turned away: the cashier enters the price they paid and
it goes into the basket as a refund, with its VAT worked out from it.

## SCOPE
May write: `app/checkout.js`, `app/test/return-no-receipt.test.html` (new).
May not write: anything else, in particular the page, `app/test/check.js`, `app/check.sh`
and the other tests.

## CONTEXT
- OpenSpec: `spec.md` of the change `add-shop-checkout`, requirement 6.
- `DOMAIN.md`, decision 3: returns without a receipt are allowed. Group 1: any price above
  0.00, no upper limit, no manager check. VAT 20 %, rounded to the cent, half up.
- The shape to build: `Checkout.addReturnWithoutReceipt(basket, price)`, `price` in cents
  with VAT, adds a line `{ name: "return without receipt", quantity: 1, amount: -price,
  vat: -(price − round(price / 1.2)) }`. A price of 0, missing, or not a number throws an
  `Error` whose message contains `price`.
- Missing today: `app/checkout.js` has no returns.
- Depends on: tickets 001 to 003.

## ACCEPTANCE
- 6.1 A return without a receipt at 35.00: the basket total is -35.00 and its VAT total -5.83.
- 6.2 A return without a receipt at 0.00, or with no price: refused, the error asks for the price.

## VERIFY
From the group folder: `sh app/check.sh test` and `sh app/check.sh lint`, both exit 0, the
earlier tests still green. The test it adds: `app/test/return-no-receipt.test.html`: 6.1
with `check()`, 6.2 with `checkThrows(..., "price")` for 0 and for no price.

## FORBIDDEN
- Returns with a receipt, payment, the end-of-day summary.
- An upper limit or a manager check (not decided).
- Touching the page; any dependency, module or Node.
- Changing, skipping or weakening any existing test.

## REPORT
Done or blocked. The files written. The commands run and their full output. Anything the
spec did not say that you needed.
