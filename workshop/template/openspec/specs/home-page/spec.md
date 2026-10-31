# home-page Specification

## Purpose
What the app in `app/` does today. This is the living documentation of the product: no one
edits it by hand. When a change is delivered, the graph archives it and copies the change's
specs here, and the reviewer checks that these specs say the same as the code.

## Requirements

### Requirement: Product name on the home page
The app SHALL show the product name, __PRODUCT__, as the page title and as the main heading.

#### Scenario: Open the app
- **WHEN** a user opens `app/index.html`
- **THEN** the page title and the main heading both read "__PRODUCT__"
