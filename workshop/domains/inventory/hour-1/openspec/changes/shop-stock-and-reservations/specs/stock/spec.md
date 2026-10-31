## ADDED Requirements

### Requirement: Stock per shop
The page SHALL show, for a product, size and colour, how many units each shop has.

#### Scenario: Two shops
- **WHEN** shop A has 3 units and shop B has 0 units of a blue shirt in size M
- **THEN** the page shows A: 3 and B: 0

### Requirement: Reserve in another shop
A staff member SHALL reserve units of a product in another shop for a customer; the reserved units SHALL stop counting as available.

#### Scenario: Reserve one
- **WHEN** shop A has 3 units and staff reserve 1 for a customer
- **THEN** shop A shows 2 available and 1 reserved

### Requirement: Reservations expire
A reservation SHALL expire after 48 hours and its units SHALL count as available again.

#### Scenario: After two days
- **WHEN** a reservation of 1 unit was made 49 hours ago
- **THEN** the unit counts as available again
