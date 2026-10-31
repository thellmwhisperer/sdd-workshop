## ADDED Requirements

### Requirement: Active promotions
The page SHALL list the promotions active on a given date, with their start and end dates.

#### Scenario: One active, one past
- **WHEN** one promotion runs this week and another ended last week
- **THEN** only this week's promotion is listed

### Requirement: Second unit at half price
When a basket has two units of a product in a 'second unit at 50 %' promotion, the second unit SHALL cost half.

#### Scenario: Two shirts
- **WHEN** a shirt costs 20.00, is in the promotion, and the basket has 2
- **THEN** the basket total is 30.00

### Requirement: Savings on the receipt
The receipt SHALL show the total saved by promotions.

#### Scenario: One promotion applied
- **WHEN** the second shirt was half price
- **THEN** the receipt shows 'You saved 10.00'
