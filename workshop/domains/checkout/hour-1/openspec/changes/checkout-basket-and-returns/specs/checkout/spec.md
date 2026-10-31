## ADDED Requirements

### Requirement: Basket total
The checkout SHALL keep a basket of lines (product, unit price with VAT, quantity, optional discount in percent) and show its total.

#### Scenario: Two lines
- **WHEN** the basket has 2 shirts at 20.00 and 1 belt at 15.00
- **THEN** the total is 55.00

### Requirement: Partial returns
With the receipt of a past sale, the cashier SHALL return some of its lines and the checkout SHALL show the amount to refund.

#### Scenario: Return one line
- **WHEN** a receipt has 2 shirts at 20.00 and the customer returns 1 shirt
- **THEN** the refund is 20.00

### Requirement: Payment and change
The checkout SHALL take payment by card or cash; for cash it SHALL show the change.

#### Scenario: Cash with change
- **WHEN** the total is 55.00 and the customer pays 60.00 in cash
- **THEN** the change shown is 5.00
