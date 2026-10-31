## ADDED Requirements

### Requirement: The till applies the saved promotions by itself
The till SHALL price every basket with the promotions saved on the promotions page that are
active today, with no choice by the cashier.

#### Scenario: 16. A promotion created by marketing reaches the till
- **WHEN** marketing saved "socks: second unit half price", active today, and the cashier adds 2 pairs of the same socks at 4.00 €
- **THEN** the till charges 6.00 € without the cashier doing anything else

### Requirement: One savings line on the receipt
The receipt SHALL end with one line, "You saved X €", with the total saving of the basket,
only when that saving is more than zero. It SHALL NOT print one savings line per item.

#### Scenario: 17. Basket with savings
- **WHEN** the basket is 1 jacket at 80.00 € with "20 % off jackets" and 2 pairs of socks at 4.00 € with "socks: second unit half price"
- **THEN** the receipt total is 70.00 € and its last line reads "You saved 18.00 €", and no other line mentions a saving

#### Scenario: 18. Basket without savings
- **WHEN** the basket is 1 cap at 15.00 € and no promotion applies to it
- **THEN** the receipt total is 15.00 € and there is no "You saved" line
