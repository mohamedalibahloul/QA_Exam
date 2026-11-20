@stock
Feature: Stock limits
  As a shop owner
  I want a cart never to hold more units than the stock
  So that customers cannot order products I do not have

  Background:
    Given the shop API is running with its initial data

  @positive
  Scenario: stc-stock-01-add exactly stock
    Given an empty cart
    When I add product 4 with quantity 3
    Then the response status is 201
    And the line of product 4 has quantity 3 and a line total of 11970

  @negative
  Scenario: stc-stock-02-add above stock
    Given an empty cart
    When I add product 4 with quantity 4
    Then the response status is 409
    And the cart is unchanged

  @negative
  Scenario: stc-stock-03-add cumulative above stock
    Given a cart containing product 4 with a quantity of 2
    When I add product 4 with quantity 2
    Then the response status is 409
    And the cart is unchanged

  @negative
  Scenario: stc-stock-04-out of stock product
    Given an empty cart
    When I add product 8 with quantity 1
    Then the response status is 409
    And the cart is unchanged

  @positive
  Scenario: stc-stock-05-patch exactly stock
    Given a cart containing product 6 with a quantity of 1
    When I change product 6 to quantity 2
    Then the response status is 200
    And the line of product 6 has quantity 2 and a line total of 11800

  @negative
  Scenario: stc-stock-06-patch above stock
    Given a cart containing product 6 with a quantity of 1
    When I change product 6 to quantity 3
    Then the response status is 409
    And the cart is unchanged

  # Setup note: each cart gets 1 unit and is then changed to 2, so this scenario
  # does not depend on stc-stock-01 (adding exactly the stock in one request).
  @negative
  Scenario: stc-stock-07-stock rechecked at checkout
    Given a cart named "A" containing product 6 with a quantity of 1
    And in cart "A" the quantity of product 6 is changed to 2
    And a cart named "B" containing product 6 with a quantity of 1
    And in cart "B" the quantity of product 6 is changed to 2
    When I check out cart "A"
    Then the response status is 201
    When I check out cart "B"
    Then the response status is 409
    And the cart "B" is still open
    And the stock of product 6 is 0