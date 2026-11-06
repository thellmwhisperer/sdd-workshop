# 010 · Returns and the summary on the screen

## GOAL
The cashier records returns on the tablet, with or without a receipt, in the same basket as
new products, and at closing Fil sees the day's summary on screen.

## SCOPE
May write: `app/index.html`, `app/screen.js`, `app/test/screen-returns.test.html` (new).
May not write: `app/checkout.js`, `app/test/check.js`, `app/check.sh` and the other tests.

## CONTEXT
- OpenSpec: `spec.md` of the change `add-shop-checkout`, requirements 5 to 8 on the screen.
- Decisions: card only; returns without a receipt allowed, any price above 0.00; the
  end-of-day summary kept (group 1).
- The shape to build, in `Screen.start`: a return with a receipt from the inputs
  `data-return-sale` and `data-return-product` and the button `data-return`; a return
  without a receipt from the input `data-return-price` (euros, like `35.00`) and the button
  `data-return-no-receipt`; the total reads "to pay" or "to refund" when it is negative; a
  button `data-summary` shows today's `data-taken`, `data-refunded`, `data-net` and
  `data-vat`. Errors from `Checkout` are shown in `data-message`.
- Missing today: the screen of ticket 009 has no returns and no summary.
- Depends on: tickets 001 to 009.

## ACCEPTANCE
- 5.1 Return one shirt of sale 1 (two at 42.00): the line reads -42.00.
- 5.3 An unknown sale number: the message says the sale was not found.
- 6.1 A return without a receipt at 35.00: the total reads 35.00 to refund.
- 6.2 No price entered: the message asks for the price.
- 7.1 A new shirt at 60.00 and the returned shirt: the total reads 18.00 to pay.
- 8.1 After those sales and refunds, the summary reads taken, refunded, net and VAT of the day.

## VERIFY
From the group folder: `sh app/check.sh test` and `sh app/check.sh lint`, both exit 0, the
earlier tests still green. The test it adds: `app/test/screen-returns.test.html`, which
clears `checkout.sales`, starts the screen in a `div`, pays sale 1 through the screen, then
fills the inputs and clicks the `data-` buttons, one `check()` per ACCEPTANCE line.

## FORBIDDEN
- Changing the arithmetic in `app/checkout.js`.
- A VAT line during the sale, a cash button, a manager check, anything from the network.
- Any dependency, module or Node.
- Changing, skipping or weakening any existing test.

## REPORT
Done or blocked. The files written. The commands run and their full output. Anything the
spec did not say that you needed.
