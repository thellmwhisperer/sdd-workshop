## Context

`app/` today is one page, `index.html`, with the title and heading "Shop checkout", and its
checks (`app/check.sh test|lint|typecheck`). The app is HTML, CSS and JavaScript loaded by
the browser as they are: no Node, no modules, no build, no dependency (STANDING.md, rule 5).
Tests are pages `app/test/<name>.test.html` that call `check()` from `app/test/check.js`.

Decisions of the group (DOMAIN.md): card only; prices with VAT included; returns without a
receipt allowed.

## Goals / Non-Goals

**Goals:**
- Basket, total with VAT included, sticker before VAT, VAT total per sale, card payment,
  returns with and without a receipt, sale and return in one basket.
- Money worked out in one place, testable without the page.

**Non-Goals:**
- Cash, change, drawer count; VAT as a separate line on screen.
- A real card terminal, stock, printed receipts, a server.

## Decisions

- **Money in cents.** Every amount is held as a whole number of cents, so 0.1 + 0.2 never
  goes wrong; shown with two decimals.
- **The rules apart from the screen.** The arithmetic (line price, sticker, VAT, totals,
  returns) lives in one script, `app/checkout.js`, with no access to the page, so each
  requirement is tested with numbers. The page, `app/index.html`, only shows and calls it.
- **VAT from a price with VAT included.** Price before VAT = price / (1 + rate), rounded to
  the cent; VAT = price minus that.
- **Sticker before VAT.** Reduced price before VAT = price before VAT × (1 − sticker),
  rounded to the cent; VAT = reduced price × rate, rounded to the cent; line = the two added.
- **Rounding to the nearest cent, half up, on each line.** (group 1)
- **VAT rate 20 %** for every product. (group 1: "20% is fine")
- **The products are a fixed list in the page**: name, price with VAT, optional sticker
  percentage. (group 1)
- **A sticker is a percentage on the product**, at most one, never typed by the cashier.
  (group 1)
- **Sales are kept on the tablet**, in the browser's local storage, numbered from 1. This is
  what makes returns with a receipt and the end-of-day summary possible. (group 1)
- **Payment by card is a button that records the sale**; the card terminal stays a separate
  machine, as today. (group 1)
- **The end-of-day summary** reads the day's sales and refunds from the tablet. (group 1)

## Risks / Trade-offs

- Sales kept on one tablet are lost if its browser data is cleared, and each counter sees
  only its own sales → a return with a receipt from another counter or shop cannot be found;
  the cashier can still use a return without a receipt.
- Returns without a receipt can refund things never bought here (two last year) → accepted
  by the group to not turn customers away (decision 3).
- Rounding half up per line can differ by a cent from rounding the whole basket → the rule
  is fixed in the spec, scenario 2.2, so the accountant can check it.
