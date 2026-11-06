# 009 · The basket on the screen

## GOAL
The cashier uses the tablet: taps products from the list, sees the lines and the total VAT
included, removes a line, and presses "Pay by card", the only way to pay.

## SCOPE
May write: `app/index.html`, `app/screen.js` (new), `app/test/screen-basket.test.html`
(new).
May not write: `app/checkout.js`, `app/test/check.js`, `app/check.sh` and the other tests.

## CONTEXT
- OpenSpec: `spec.md` of the change `add-shop-checkout`, requirements 1 and 4 on the
  screen; scenario 4.2.
- Decisions: card only; prices VAT included, no VAT line on screen; a fixed product list in
  the page (group 1).
- The product list: the products of the spec's scenarios: shirt 60.00, shirt 60.00 with a
  30 % sticker, scarf 25.00, jumper 39.90 with a 15 % sticker.
- The shape to build: `app/screen.js` defines `Screen.start(root, products)`, which draws
  into the element `root` and uses `Checkout` for every amount. One button per product with
  `data-product="<name>"`; each line with `data-line`, its remove button `data-remove`; the
  total `data-total`; one pay button `data-pay`; messages in `data-message`.
  `app/index.html` loads `checkout.js` and `screen.js` and calls `Screen.start`. The title
  and heading "Shop checkout" stay.
- Missing today: `app/index.html` has only the title and heading.
- Depends on: tickets 001 to 005.

## ACCEPTANCE
- 1.1 Tapping the shirt at 60.00: one line at 60.00, total 60.00.
- 1.3 Tapping it twice: one line, quantity 2, at 120.00.
- 1.4 Shirt and scarf, scarf removed: total 60.00.
- 4.1 Pay by card: the basket is empty again and the sale is recorded.
- 4.2 Card is the only method: one pay button, and the word "cash" is nowhere on the screen.
- 4.3 Pay with an empty basket: the message says the basket is empty.

## VERIFY
From the group folder: `sh app/check.sh test` and `sh app/check.sh lint`, both exit 0, the
earlier tests still green (`page.test.sh` too). The test it adds:
`app/test/screen-basket.test.html`, which clears `checkout.sales`, makes a `div`, calls
`Screen.start`, clicks the `data-` buttons and checks the screen's text, one `check()` per
ACCEPTANCE line.

## FORBIDDEN
- Changing the arithmetic in `app/checkout.js`; returns and summary on screen (ticket 010).
- A VAT line, a cash button, anything loaded from the network.
- Any dependency, module or Node.
- Changing, skipping or weakening any existing test.

## REPORT
Done or blocked. The files written. The commands run and their full output. Anything the
spec did not say that you needed.
