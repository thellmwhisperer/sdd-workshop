# 011 · A supermarket look: Carrefour colours on every page

## GOAL

The three pages of the app look like one shop, in the style of a big supermarket such as Carrefour: its blue and red, a header bar with links to every page, and a clear front page. Today the pages are bare browser defaults and the front page is empty.

## SCOPE

May write: `app/theme.css` (new), `app/index.html`, `app/promotions.html`, `app/till.html`, `app/test/theme.test.sh` (new).
May not write: `app/pricing.js`, `app/receipt.js`, `app/store.js`, `app/products.js`, any existing test, or any other file.

## CONTEXT

The client asked on 31 October for the site to look like Carrefour. The theme, as Carrefour's brand colours list it: blue `#254F9B` (main colour: header bar, buttons, table headers), red `#C20016` (accent: prices, discounts, the delete button), white backgrounds, dark grey text `#313131`. Plain, rounded, friendly: rounded corners on buttons and inputs, a bold sans-serif from the system (`system-ui, Arial, sans-serif`), generous spacing, tables with light row lines. The shop is Brisa (`DOMAIN.md`): the header says "Brisa", never "Carrefour", and there is no Carrefour logo or image. `app/check.sh lint` forbids loading anything from the network: no web fonts, no CDN, no images from outside. One stylesheet, `app/theme.css`, linked from all three pages. Only the look changes: keep every id, field and button the existing tests and scripts use. Ticket 010 changes the Category field of `app/promotions.html` at the same time; this ticket runs after 010 is merged.

## ACCEPTANCE

- 22 · `app/theme.css` exists and uses the blue `#254F9B` and the red `#C20016`.
- 23 · `index.html`, `promotions.html` and `till.html` each link `theme.css` and nothing from the network.
- 24 · Each of the three pages has a header with the name "Brisa" and links to `index.html`, `promotions.html` and `till.html`.
- 25 · The front page `index.html` says what the app is for and links to the promotions page and the till.

## VERIFY

`sh app/check.sh test` and `sh app/check.sh lint` are green, and `app/test/theme.test.sh` prints one `ok` line per scenario 22-25.

## FORBIDDEN

- Do not change how prices, promotions or the till work.
- Do not rename or remove an id, field or button the pages or tests use.
- Do not use the word "Carrefour", its logo or any of its images in the app.
- Do not touch `openspec/`, `DOMAIN.md`, `tickets/`, `graph/` or `STANDING.md`.
- No new dependency, no Node, no module, no build step, nothing loaded from the network.
- Do not weaken, skip or delete an existing test to get green.

## REPORT

Say **done** or **blocked** (and what is missing). List the files you changed, the test
pages you added, the command you ran and its last lines of output.
