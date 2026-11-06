# 005 · Card payment records the sale

## GOAL
When the card terminal accepts, the cashier closes the basket: the sale is kept on the
tablet with its number, lines, total, VAT total and the method "card", and a new basket
starts.

## SCOPE
May write: `app/checkout.js`, `app/test/payment.test.html` (new).
May not write: anything else, in particular the page, `app/test/check.js`, `app/check.sh`
and the other tests.

## CONTEXT
- OpenSpec: `spec.md` of the change `add-shop-checkout`, requirement 4 (scenarios 4.1 and
  4.3; 4.2 is on the screen, ticket 009).
- `DOMAIN.md`, decision 1: card only. Group 1: payment is a button pressed after the
  terminal accepts, no link to the terminal; sales kept on the tablet, numbered from 1.
- The shape to build: `Checkout.pay(basket)` records `{ number, day, lines, total, vat,
  method: "card" }` in the browser's `localStorage` under the key `checkout.sales` (a JSON
  array), empties `basket.lines`, and returns the sale. `day` is the tablet's local date,
  `YYYY-MM-DD`. `Checkout.sales()` returns the recorded sales. An empty basket throws an
  `Error` whose message contains `basket is empty`, and nothing is recorded.
- Missing today: nothing in `app/` records a sale.
- Depends on: tickets 001 to 003.

## ACCEPTANCE
- 4.1 A basket of 102.00 with VAT 17.00 paid by card: sale 1 recorded, total 102.00, VAT 17.00, method card; the basket is empty.
- 4.3 An empty basket paid: refused with "basket is empty", no sale recorded.

## VERIFY
From the group folder: `sh app/check.sh test` and `sh app/check.sh lint`, both exit 0, the
earlier tests still green. The test it adds: `app/test/payment.test.html`, which first
removes `checkout.sales` from `localStorage`, then checks 4.1 with `check()` (number, total,
VAT, method, lines left) and 4.3 with `checkThrows` and the count of sales.

## FORBIDDEN
- Cash, change, a drawer, or any link to a card terminal.
- Returns, the summary, the page.
- A server, any dependency, module or Node.
- Changing, skipping or weakening any existing test.

## REPORT
Done or blocked. The files written. The commands run and their full output. Anything the
spec did not say that you needed.
