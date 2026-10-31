## ADDED Requirements

### Requirement: Marketing creates and lists promotions
The promotions page SHALL let marketing create a promotion with a name, a kind (percent,
second half, three for two), a category, a percent (kind percent only), a start date and an
end date, and SHALL list every saved promotion with those fields.

#### Scenario: 11. Create a promotion
- **WHEN** marketing saves "20 % off jackets", kind percent, category jackets, 20 %, from 2026-10-26 to 2026-11-01
- **THEN** the list shows that promotion with those six fields, and it is still there after the page is reloaded

### Requirement: The page refuses a broken promotion
The page SHALL refuse to save a promotion with an empty name or category, a percent that is
not between 1 and 100, or an end date before its start date, and SHALL say which field is
wrong.

#### Scenario: 12. Percent over 100
- **WHEN** marketing tries to save a percent promotion at 120 %
- **THEN** nothing is saved and the page says the percent must be between 1 and 100

#### Scenario: 13. End before start
- **WHEN** marketing tries to save a promotion from 2026-11-01 to 2026-10-26
- **THEN** nothing is saved and the page says the end date is before the start date

### Requirement: Marketing edits and deletes promotions
The page SHALL let marketing change any field of a saved promotion, with the same checks as
when creating it, and delete it.

#### Scenario: 14. Edit a promotion
- **WHEN** marketing changes "20 % off jackets" to 25 %
- **THEN** the list shows 25 % and the till prices a jacket at 80.00 € as 60.00 €

#### Scenario: 15. Delete a promotion
- **WHEN** marketing deletes "20 % off jackets"
- **THEN** it is no longer in the list and the till prices a jacket at 80.00 € as 80.00 €
