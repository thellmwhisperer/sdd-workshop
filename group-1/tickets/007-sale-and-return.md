# 007 · Sale and return in one basket

## GOAL
A customer who swaps one item for another settles everything in one go: the basket nets the
new products against the returns, and the difference is paid by card or refunded to it.

## SCOPE
May write: `app/checkout.js`, `app/test/sale-and-return.test.html` (new).
May not write: anything else, in particular the page, `app/test/check.js`, `app/check.sh`
and the other tests.

## CONTEXT
- OpenSpec: `spec.md` of the change `add-shop-checkout`, requirement 7.
- Decision 1: card only, so a negative total is refunded to the card.
- The shape to build: `Checkout.total` and `Checkout.vat` already add every line, returns
  included. `Checkout.pay` must accept a basket whose total is negative and record it with
  that negative total and VAT, method `card`. A basket of only returns is a refund, not an
  empty basket.
- Missing today: nothing tests a basket with both; it is not known whether `pay` accepts a
  negative total.
- Depends on: tickets 001 to 006.

## ACCEPTANCE
- 7.1 A new shirt at 60.00 and a returned shirt at 42.00 from sale 1: total 18.00 to pay, VAT 3.00.
- 7.2 A new scarf at 25.00 and a returned shirt at 42.00 from sale 1: total -17.00 to refund, VAT -2.83.

## VERIFY
From the group folder: `sh app/check.sh test` and `sh app/check.sh lint`, both exit 0, the
earlier tests still green. The test it adds: `app/test/sale-and-return.test.html`, which
clears `checkout.sales`, pays sale 1 (two shirts at 60.00 with a 30 % sticker), then checks
7.1 and 7.2 with `check()` on the totals and on the sale that `Checkout.pay` returns.

## FORBIDDEN
- Cash, or refunding any other way than to the card.
- The summary, the page.
- Any dependency, module or Node.
- Changing, skipping or weakening any existing test.

## REPORT
Done or blocked. The files written. The commands run and their full output. Anything the
spec did not say that you needed.
