# 006 · Return with a receipt

## GOAL
With a receipt, the customer gets back exactly what they paid for the item, sticker
included, found from the original sale, and never more items than they bought.

## SCOPE
May write: `app/checkout.js`, `app/test/return-receipt.test.html` (new).
May not write: anything else, in particular the page, `app/test/check.js`, `app/check.sh`
and the other tests.

## CONTEXT
- OpenSpec: `spec.md` of the change `add-shop-checkout`, requirement 5.
- Group 1: sales kept on the tablet (`localStorage`, key `checkout.sales`, ticket 005).
- The shape to build: `Checkout.addReturn(basket, saleNumber, name)` finds the sale in
  `Checkout.sales()` and adds a line `{ name, quantity: 1, amount: -<unit price paid>,
  vat: -<unit VAT paid>, returnOf: saleNumber }`, the unit price and VAT taken from that
  sale's line. Items already returned are the `returnOf` lines for that sale and name in the
  recorded sales and in the basket. Throws an `Error` containing `sale not found` for an
  unknown number, and `nothing left to return` when all of them are returned.
- Missing today: `app/checkout.js` cannot find a past sale.
- Depends on: tickets 001 to 005.

## ACCEPTANCE
- 5.1 Sale 1 had two shirts at 42.00 (30 % sticker); one returned: refund 42.00, VAT 7.00.
- 5.2 Both shirts of sale 1 already returned, one more tried: refused, "nothing left to return".
- 5.3 A sale number that does not exist: refused, "sale not found".

## VERIFY
From the group folder: `sh app/check.sh test` and `sh app/check.sh lint`, both exit 0, the
earlier tests still green. The test it adds: `app/test/return-receipt.test.html`, which
clears `checkout.sales`, pays sale 1 with `Checkout.pay`, then checks 5.1 with `check()`
and 5.2 and 5.3 with `checkThrows`.

## FORBIDDEN
- Returns without a receipt (ticket 004), the summary, the page.
- Refunding more than was paid for the item.
- Any dependency, module or Node.
- Changing, skipping or weakening any existing test.

## REPORT
Done or blocked. The files written. The commands run and their full output. Anything the
spec did not say that you needed.
