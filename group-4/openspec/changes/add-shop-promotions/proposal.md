# Proposal

## Why

Brisa's cashiers apply the week's promotions by hand from a printed PDF. One promoted
basket in eight is charged wrong (about 3,100 euros a month), and a jacket got 20 % off
twice because it was in two promotions at once. Jorge wants promotions defined once and
applied at every till before Black Friday, so no cashier has to remember one and the
Monday complaints stop.

## What Changes

- Marketing creates, edits and deletes promotions on a page of the app, with no help from
  IT (decision 1).
- Three kinds of promotion: X % off a category, second unit at half price, buy 3 pay 2.
- Each promotion runs between a start date and an end date.
- The till applies promotions automatically; the cashier does not pick them (decision 2).
- Promotions never stack: each product gets at most one promotion, the one that saves the
  customer the most.
- The receipt shows one line at the bottom, "You saved X €", only when the customer
  saved something (decision 3).

Out of scope: cashier overrides, one savings line per item, stacking promotions, any file
IT edits by hand.

## Capabilities

### New Capabilities
- `promotion-pricing`: how the active promotions turn a basket into prices: the three
  kinds, the dates, and the one-best-promotion-per-product rule.
- `promotions-page`: the page where marketing creates, edits, deletes and lists
  promotions, and what it refuses.
- `till-receipt`: the till that prices a basket with the saved promotions and prints the
  receipt with its savings line.

### Modified Capabilities
- None.

## Impact

New files in `app/`: the pricing code, the promotions page, the till page, and their test
pages in `app/test/`. No new dependency: HTML, CSS and JavaScript as the browser loads them.
