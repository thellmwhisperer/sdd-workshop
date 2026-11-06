# 008 · End-of-day summary

## GOAL
At closing, Fil gets the day's card total taken, card total refunded, the net and the VAT
total, so the screen can be matched against the card terminal without sticky notes.

## SCOPE
May write: `app/checkout.js`, `app/test/summary.test.html` (new).
May not write: anything else, in particular the page, `app/test/check.js`, `app/check.sh`
and the other tests.

## CONTEXT
- OpenSpec: `spec.md` of the change `add-shop-checkout`, requirement 8.
- Group 1: keep the end-of-day summary in the first version; sales kept on the tablet.
- The shape to build: `Checkout.summary(sales)` takes a list of recorded sales and returns
  `{ taken, refunded, net, vat }` in cents: `taken` the sum of the positive totals,
  `refunded` the sum of the negative totals as a positive amount, `net` = taken − refunded,
  `vat` the sum of every sale's VAT. `Checkout.daySales(day)` returns the recorded sales
  whose `day` is `day`.
- Missing today: nothing adds the sales of a day.
- Depends on: tickets 001 to 007.

## ACCEPTANCE
- 8.1 Sales of 102.00 (VAT 17.00) and 18.00 (VAT 3.00), and a refund of 42.00 (VAT 7.00): taken 120.00, refunded 42.00, net 78.00, VAT 13.00.

## VERIFY
From the group folder: `sh app/check.sh test` and `sh app/check.sh lint`, both exit 0, the
earlier tests still green. The test it adds: `app/test/summary.test.html`, one `check()`
for 8.1 on `Checkout.money` of the four amounts, from a list of three sales written in the
test, and one on `Checkout.daySales` keeping only the sales of the given day.

## FORBIDDEN
- Cash, drawer counts, printing, sending the summary anywhere.
- The page.
- Any dependency, module or Node.
- Changing, skipping or weakening any existing test.

## REPORT
Done or blocked. The files written. The commands run and their full output. Anything the
spec did not say that you needed.
