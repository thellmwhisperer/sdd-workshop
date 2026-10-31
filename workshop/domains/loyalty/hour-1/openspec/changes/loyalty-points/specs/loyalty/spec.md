## ADDED Requirements

### Requirement: Earn points
Each purchase SHALL add 1 point per whole euro spent to the customer, identified by phone number.

#### Scenario: A purchase
- **WHEN** a customer with 0 points buys for 42.80
- **THEN** the customer has 42 points

### Requirement: Spend points
At the till, a customer with at least 100 points SHALL spend them in blocks of 100, each block taking 5.00 off the total.

#### Scenario: One block
- **WHEN** a customer has 130 points and the total is 30.00
- **THEN** after spending one block the total is 25.00 and 30 points are left

### Requirement: Customer history
The page SHALL show a customer's purchases and point movements, newest first.

#### Scenario: Two movements
- **WHEN** a customer earned 42 points and later spent 100
- **THEN** the history shows the spend first, then the earn
