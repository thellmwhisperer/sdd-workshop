# 010 · Promotions page: choose the category from the shop's own

## GOAL

Marketing picks a promotion's category from the categories the shop sells, so a promotion can never miss its products because of a typo or a capital letter.

## SCOPE

May write: `app/promotions.html`, `app/test/promotions-category.test.html` (new).
May not write: `app/pricing.js`, `app/products.js`, `app/store.js` or any other file.

## CONTEXT

Found on the live site on 31 October: a 10 % promotion typed with category "Socks" never applied at the till, because the product's category is "socks" (`app/products.js`) and `app/pricing.js` compares categories exactly. Today the Category field of `app/promotions.html` is free text. The categories the shop sells are the `category` values of `Products` in `app/products.js`: `jackets`, `socks`, `t-shirts`, `caps`. Load `products.js` in the page and build the choice from it; do not copy the list by hand. Depends on tickets 007 and 009.

## ACCEPTANCE

- 19 · The Category field of the page is a list offering exactly the categories of `Products`, each once: jackets, socks, t-shirts, caps. No free text can be typed.
- 20 · Creating a 10 % percent promotion choosing "socks", valid today: 10 socks at the till are priced 36.00 €.
- 21 · Editing an existing promotion shows its category already chosen in the list, and saving keeps it.

## VERIFY

`sh app/check.sh test` is green, and `app/test/promotions-category.test.html` prints one `ok` line per scenario 19-21.

## FORBIDDEN

- Do not change the till, the pricing rules or the products.
- Do not touch `openspec/`, `DOMAIN.md`, `tickets/`, `graph/` or `STANDING.md`.
- No new dependency, no Node, no module, no build step.
- Do not weaken, skip or delete an existing test to get green.

## REPORT

Say **done** or **blocked** (and what is missing). List the files you changed, the test
pages you added, the command you ran and its last lines of output.
