## ADDED Requirements

### Requirement: Percent off a category
A promotion of kind "percent" SHALL take its percent off the price of every unit of every
product in its category. Amounts are rounded to the cent.

#### Scenario: 1. Jacket at 20 % off jackets
- **WHEN** the basket holds 1 jacket at 80.00 € and "20 % off jackets" is active
- **THEN** the jacket costs 64.00 € and the saving is 16.00 €

#### Scenario: 2. Product outside the category
- **WHEN** the basket holds 1 cap (category caps) at 15.00 € and "20 % off jackets" is active
- **THEN** the cap costs 15.00 € and the saving is 0.00 €

### Requirement: Second unit at half price
A promotion of kind "second half" SHALL charge every second unit of the same product in its
category at half price.

#### Scenario: 3. Two pairs of socks
- **WHEN** the basket holds 2 pairs of the same socks at 4.00 € and "socks: second unit half price" is active
- **THEN** the socks cost 6.00 € and the saving is 2.00 €

#### Scenario: 4. Three pairs of socks
- **WHEN** the basket holds 3 pairs of the same socks at 4.00 € and "socks: second unit half price" is active
- **THEN** the socks cost 10.00 € and the saving is 2.00 €

### Requirement: Buy 3 pay 2
A promotion of kind "three for two" SHALL make every third unit of the same product in its
category free.

#### Scenario: 5. Three T-shirts
- **WHEN** the basket holds 3 of the same T-shirt at 10.00 € and "T-shirts: buy 3 pay 2" is active
- **THEN** the T-shirts cost 20.00 € and the saving is 10.00 €

#### Scenario: 6. Two T-shirts
- **WHEN** the basket holds 2 of the same T-shirt at 10.00 € and "T-shirts: buy 3 pay 2" is active
- **THEN** the T-shirts cost 20.00 € and the saving is 0.00 €

### Requirement: One promotion per product, the best for the customer
Promotions SHALL never stack. When more than one active promotion applies to a product, the
product SHALL get only the one that saves the customer the most.

#### Scenario: 7. Jacket in two promotions
- **WHEN** the basket holds 1 jacket at 80.00 € and both "20 % off jackets" and "10 % off jackets" are active
- **THEN** the jacket costs 64.00 € and the saving is 16.00 €, never 23.20 €

#### Scenario: 8. The better of two kinds
- **WHEN** the basket holds 3 pairs of the same socks at 4.00 € and both "socks: second unit half price" and "socks: buy 3 pay 2" are active
- **THEN** the socks cost 8.00 € and the saving is 4.00 €

### Requirement: Only promotions in their dates
A promotion SHALL apply only from its start date to its end date, both included.

#### Scenario: 9. Promotion that ended
- **WHEN** "20 % off jackets" ran from 2026-10-19 to 2026-10-25 and the basket is priced on 2026-10-26 with 1 jacket at 80.00 €
- **THEN** the jacket costs 80.00 € and the saving is 0.00 €

#### Scenario: 10. Last day of a promotion
- **WHEN** "20 % off jackets" runs from 2026-10-26 to 2026-11-01 and the basket is priced on 2026-11-01 with 1 jacket at 80.00 €
- **THEN** the jacket costs 64.00 €
