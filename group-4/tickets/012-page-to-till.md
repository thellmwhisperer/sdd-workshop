# 012 · A promotion made on the page prices at the till, for every kind

## GOAL

Every kind of promotion Marketing creates on the promotions page changes the price at the till. Today a "second half" promotion made on the page never applies.

## SCOPE

May write: `app/pricing.js`, `app/test/page-to-till.test.html` (new).
May not write: `app/promotions.html`, `app/till.html`, `app/store.js`, `app/receipt.js`, `app/products.js`, any existing test, or any other file.

## CONTEXT

Found on 31 October by the worker of ticket 010. The page saves the kinds as `percent`, `second-half` and `three-for-two` (the option values in `app/promotions.html`). `app/pricing.js` recognises `second half` with a space and never `second-half`, so the promotion is stored but never matches. `three-for-two` works only because pricing already accepts both spellings. Tickets 002 (pricing) and 007 (page) ran side by side, each with its own tests, and no test went from the page to the price. Rules: "Second unit at half price" and "Buy 3 pay 2" in `openspec/changes/add-shop-promotions/specs/promotion-pricing/spec.md`. Pricing must accept both spellings of each kind, so the promotions already saved keep working. Look at `app/test/promotions-category.test.html` to see how a test drives the page. Socks cost 4.00 €, category `socks`.

## ACCEPTANCE

- 26 · A "second half" promotion on socks, created through the page and valid today: 2 pairs of socks at the till are priced 6.00 €.
- 27 · A "three for two" promotion on socks, created through the page and valid today: 3 pairs of socks are priced 8.00 €.
- 28 · A 10 % "percent" promotion on socks, created through the page and valid today: 10 pairs of socks are priced 36.00 €.
- 29 · A promotion stored with the kind `second half` (with a space) still prices 2 pairs of socks at 6.00 €.

## VERIFY

`sh app/check.sh test` and `sh app/check.sh lint` are green, and `app/test/page-to-till.test.html` prints one `ok` line per scenario 26-29.

## FORBIDDEN

- Do not change the page, the till, the store or the products.
- Do not change the pricing rules themselves: only which kind names they recognise.
- Do not touch `openspec/`, `DOMAIN.md`, `tickets/`, `graph/` or `STANDING.md`.
- No new dependency, no Node, no module, no build step.
- Do not weaken, skip or delete an existing test to get green.

## REPORT

Say **done** or **blocked** (and what is missing). List the files you changed, the test
pages you added, the command you ran and its last lines of output.
