# 001 · Basket and total

## GOAL
The cashier can put products in a basket and get each line and the basket total, VAT
included, exactly as on the shelf. This ticket builds the arithmetic only; the screen comes
in ticket 009.

## SCOPE
May write: `app/checkout.js` (new), `app/test/basket.test.html` (new).
May not write: anything else, in particular `app/index.html`, `app/test/check.js`,
`app/check.sh` and the other tests.

## CONTEXT
- OpenSpec: `openspec/changes/add-shop-checkout/specs/checkout/spec.md`, requirement 1.
- `DOMAIN.md`, decision 2: prices are shown with VAT included.
- `design.md`: money is held as whole cents; the rules live in `app/checkout.js`, a plain
  script with no access to the page, that defines one global object, `Checkout`.
- The shape to build: a product is `{ name, price }` with `price` in cents, VAT included.
  `Checkout.newBasket()` returns `{ lines: [] }`. `Checkout.add(basket, product)` adds the
  product: a product already in the basket raises its line's `quantity` by 1. A line is
  `{ name, quantity, amount }`, `amount` in cents. `Checkout.remove(basket, name)` removes
  that line. `Checkout.total(basket)` returns the total in cents. `Checkout.money(cents)`
  returns the amount with two decimals, for example `"60.00"`, `"0.00"`, `"-2.83"`.
- Missing today: `app/` has no `checkout.js`; only `index.html` and its tests.
- Depends on: nothing.

## ACCEPTANCE
- 1.1 Adding a shirt at 60.00: one line at 60.00, total 60.00.
- 1.2 A shirt at 60.00 and a scarf at 25.00: total 85.00.
- 1.3 The shirt at 60.00 twice: one line, quantity 2, at 120.00; total 120.00.
- 1.4 Shirt at 60.00 and scarf at 25.00, scarf removed: total 60.00.
- 1.5 An empty basket: total 0.00.

## VERIFY
From the group folder: `sh app/check.sh test` and `sh app/check.sh lint`, both exit 0.
The test it adds: `app/test/basket.test.html`, loading `../checkout.js` and `check.js`,
with one `check()` per ACCEPTANCE line, named by its number (for example `1.3 same product
twice`), comparing `Checkout.money(...)` of the totals and the line's quantity.

## FORBIDDEN
- Stickers, VAT, payment, returns or anything from requirements 2 to 8.
- Touching the page (`app/index.html`).
- `import`, `export`, `require`, Node, npm, or any dependency.
- Changing, skipping or weakening any existing test.

## REPORT
Done or blocked. The files written. The commands run and their full output. Anything the
spec did not say that you needed (blocked, not guessed).
