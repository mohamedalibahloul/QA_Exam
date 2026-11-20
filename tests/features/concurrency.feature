@conc
Feature: Checkouts at the same time
  As a shop owner
  I want the stock never to become negative
  So that two customers can never buy the same last units

  Background:
    Given the shop API is running with its initial data

  # Setup note: each cart gets 1 unit of the vase and is then changed to 2, so this scenario
  # does not depend on stc-stock-01 (adding exactly the stock in one request).
  @negative
  Scenario: stc-conc-01-parallel checkout same stock
    Given a cart named "A" containing product 6 with a quantity of 1
    And in cart "A" the quantity of product 6 is changed to 2
    And a cart named "B" containing product 6 with a quantity of 1
    And in cart "B" the quantity of product 6 is changed to 2
    When I check out all the carts at the same time
    Then exactly 1 checkouts succeed and 1 are refused with status 409
    And the stock of product 6 is 0

  @negative
  Scenario: stc-conc-02-parallel checkout many carts
    Given 5 carts each containing product 6 with a quantity of 1
    When I check out all the carts at the same time
    Then exactly 2 checkouts succeed and 3 are refused with status 409
    And the stock of product 6 is 0