## ADDED Requirements

All amounts are in euros, to the cent. Every price shown includes VAT (decision 2). The
examples use a VAT rate of 20 %, the rate for every product (group 1).

### Requirement: 1. Basket and total
The cashier SHALL add products to a basket and see each line and the basket total, with VAT
included, as on the shelf.

#### Scenario: 1.1 One product
- **WHEN** the cashier adds a shirt priced 60.00
- **THEN** the basket shows one line at 60.00 and the total reads 60.00

#### Scenario: 1.2 Two products
- **WHEN** the cashier adds a shirt at 60.00 and a scarf at 25.00
- **THEN** the total reads 85.00

#### Scenario: 1.3 Same product twice
- **WHEN** the cashier adds the shirt at 60.00 twice
- **THEN** the basket shows one line, quantity 2, at 120.00, and the total reads 120.00

#### Scenario: 1.4 Remove a line
- **WHEN** the basket holds the shirt at 60.00 and the scarf at 25.00, and the cashier removes the scarf
- **THEN** the total reads 60.00

#### Scenario: 1.5 Empty basket
- **WHEN** the basket has no lines
- **THEN** the total reads 0.00

### Requirement: 2. Discount sticker before VAT
A discount sticker SHALL come off the price before VAT, never after: the price without VAT
is reduced by the sticker's percentage and rounded to the cent, then the VAT is added on the
reduced price and rounded to the cent.

#### Scenario: 2.1 A 30 % sticker
- **WHEN** the cashier adds a shirt priced 60.00 (50.00 before VAT) with a 30 % sticker
- **THEN** the line reads 42.00: 35.00 before VAT plus 7.00 VAT

#### Scenario: 2.2 Before VAT, not after
- **WHEN** the cashier adds a jumper priced 39.90 (33.25 before VAT) with a 15 % sticker
- **THEN** the line reads 33.91 (28.26 before VAT plus 5.65 VAT), not 33.92 (15 % off 39.90)

#### Scenario: 2.3 No sticker
- **WHEN** the cashier adds a shirt priced 60.00 with no sticker
- **THEN** the line reads 60.00

### Requirement: 3. VAT total of each sale
Every sale SHALL carry its VAT total, the sum of the VAT of its lines, for the accountant.
The screen shows prices with VAT included; the VAT total is recorded with the sale.

#### Scenario: 3.1 VAT of a basket with a sticker
- **WHEN** the basket holds a shirt at 60.00 and a shirt at 60.00 with a 30 % sticker
- **THEN** the total is 102.00 and the sale's VAT total is 17.00 (10.00 plus 7.00)

#### Scenario: 3.2 VAT of a price without sticker
- **WHEN** the basket holds a scarf at 25.00
- **THEN** the sale's VAT total is 4.17 (20.83 before VAT)

### Requirement: 4. Card payment only
The checkout SHALL take payment by card only (decision 1). Paying closes the basket and
records the sale with a number, its lines, its total, its VAT total and the method "card".

#### Scenario: 4.1 Pay a basket by card
- **WHEN** the basket totals 102.00 with a VAT total of 17.00 and the cashier takes payment by card
- **THEN** a sale is recorded with its number, total 102.00, VAT total 17.00, method card, and the basket is empty again

#### Scenario: 4.2 No cash
- **WHEN** the cashier takes payment
- **THEN** card is the only method offered; there is no cash option and no change to give

#### Scenario: 4.3 Empty basket
- **WHEN** the basket is empty and the cashier tries to take payment
- **THEN** no sale is recorded and the screen says the basket is empty

### Requirement: 5. Return with a receipt
With a receipt, the cashier SHALL find the original sale by its number and pick the items
returned; the refund is exactly what was paid for those items, sticker included, with their
VAT. An item cannot be returned more times than it was bought.

#### Scenario: 5.1 Part of a sale
- **WHEN** sale 1 had two shirts at 42.00 each (30 % sticker) and the customer returns one
- **THEN** the refund is 42.00 with a VAT of 7.00

#### Scenario: 5.2 Not more than was bought
- **WHEN** both shirts of sale 1 have already been returned and the cashier tries to return one more
- **THEN** the return is refused and the screen says nothing is left to return on that sale

#### Scenario: 5.3 Unknown sale
- **WHEN** the cashier enters a sale number that does not exist
- **THEN** the return is refused and the screen says the sale was not found

### Requirement: 6. Return without a receipt
Without a receipt the return SHALL be allowed (decision 3): the cashier enters the price paid,
VAT included, and the refund is that price with its VAT worked out from it. Any price above
0.00 is accepted, with no upper limit and no manager check (group 1).

#### Scenario: 6.1 Refund an entered price
- **WHEN** the cashier records a return without a receipt at 35.00
- **THEN** the refund is 35.00 with a VAT of 5.83 (29.17 before VAT)

#### Scenario: 6.2 A price must be given
- **WHEN** the cashier enters 0.00 or no price for a return without a receipt
- **THEN** the return is refused and the screen asks for the price

### Requirement: 7. Sale and return in one basket
A basket SHALL hold new products and returned items together. Its total is the new products
minus the returns: when positive the customer pays it by card, when negative it is refunded
to the card. The sale's VAT total is the VAT of the new products minus the VAT of the returns.

#### Scenario: 7.1 The customer pays the difference
- **WHEN** the basket holds a new shirt at 60.00 and a returned shirt at 42.00 from sale 1
- **THEN** the total reads 18.00 to pay by card and the VAT total is 3.00

#### Scenario: 7.2 The customer gets the difference back
- **WHEN** the basket holds a new scarf at 25.00 and a returned shirt at 42.00 from sale 1
- **THEN** the total reads 17.00 to refund to the card and the VAT total is -2.83

### Requirement: 8. End-of-day summary
At closing time the checkout SHALL show the day's card total taken, card total refunded,
the net of both, and the VAT total, so the screen can be matched against the card terminal.

#### Scenario: 8.1 A day with two sales and one refund
- **WHEN** the day had a sale of 102.00 (VAT 17.00), a sale of 18.00 (VAT 3.00) and a refund of 42.00 (VAT 7.00)
- **THEN** the summary reads taken 120.00, refunded 42.00, net 78.00, VAT total 13.00
