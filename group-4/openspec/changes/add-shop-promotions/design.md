# Design

## Context

`app/` is one page, `index.html`, with a title and a heading. The app is HTML, CSS and
JavaScript exactly as a browser loads them: no Node, no build, no dependency. Tests are
pages `app/test/<name>.test.html` that load `test/check.js` and print `ok`/`FAIL` lines;
`sh app/check.sh test` runs them.

## Goals / Non-Goals

**Goals:**
- One pricing function that every page uses, tested on its own with the numbers of the spec.
- A promotions page for marketing and a till page for the cashier, sharing saved promotions.

**Non-Goals:**
- Sharing promotions between machines or shops (no server here).
- Cashier overrides, per-item savings lines, stacking.

## Decisions

- **Pricing in one file, `app/pricing.js`**, a plain script that defines one global
  (`Pricing`) with a function that takes a basket, the promotions and a date and returns the
  price of each line, the total and the saving. Pages and tests load it with `<script>`.
- **Money in whole cents** inside the code, shown as `0.00 €`; this keeps 20 % of 80.00 €
  exact.
- **Best promotion per product**: for each product line, compute the saving of each active
  promotion of its category and keep the largest. Equal savings: the first one saved wins.
- **Promotions saved in the browser's `localStorage`** under one key, read by both the
  promotions page (`app/promotions.html`) and the till (`app/till.html`). (proposal) It is
  the only storage a browser-only app has; real shops would need a shared store later.
- **The till's products** come from a short fixed list in `app/products.js` (jacket 80.00 €,
  socks 4.00 €, T-shirt 10.00 €, cap 15.00 €), each with a category. (proposal) The brief
  has no catalogue; this is only what the till needs to be tried.
- **Dates** as `YYYY-MM-DD` strings, compared as text; both ends included.

## Risks / Trade-offs

- `localStorage` is per browser: a promotion saved on marketing's computer does not reach a
  till on another one. Acceptable for this app; named as the next need.
- Ties between equal promotions are resolved by order, not by a business rule; the brief
  only says "the best one for the customer", and equal savings cost the customer the same.
