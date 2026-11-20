@chk
Feature: Checkout
  As a shopper
  I want to turn my cart into an order
  So that I can pay for what I chose

  Background:
    Given the shop API is running with its initial data

  @smoke @positive
  Scenario: stc-chk-01-checkout success
    Given a cart containing product 1 with a quantity of 2
    When I check out the cart
    Then the response status is 201
    And the order is waiting for payment
    And the order contains product 1 with a quantity of 2
    And the order amounts are the same as the cart amounts
    And the cart status is "checked_out"
    And the stock of product 1 is 23

  @positive
  Scenario: stc-chk-02-order totals with promo
    Given a cart containing product 1 with a quantity of 2
    And the promo code "WELCOME10" is applied
    When I check out the cart
    Then the response status is 201
    And the amounts are: subtotal 3990, discount 399, shipping 490, total 4081

  @positive
  Scenario: stc-chk-03-multi line stock decrease
    Given a cart containing product 1 with a quantity of 2
    And the cart also contains product 4 with a quantity of 1
    When I check out the cart
    Then the response status is 201
    And the stock of product 1 is 23
    And the stock of product 4 is 2

  @negative
  Scenario: stc-chk-04-empty cart
    Given an empty cart
    When I check out the cart
    Then the response status is 422
    And the response contains an error message
    And the cart status is "open"

  @negative
  Scenario: stc-chk-05-already checked out
    Given a cart containing product 1 with a quantity of 2
    And the cart is checked out
    When I check out the cart
    Then the response status is 409
    And the order "o2" does not exist
    And the stock of product 1 is 23

  @negative
  Scenario: stc-chk-06-unknown cart
    When I check out the cart "c999"
    Then the response status is 404

  @negative
  Scenario: stc-chk-07-cart frozen after checkout
    Given a cart containing product 1 with a quantity of 1
    And the cart is checked out
    When I add product 2 with quantity 1
    Then the response status is 409
    When I change product 1 to quantity 2
    Then the response status is 409
    When I remove product 1
    Then the response status is 409
    And the cart is unchanged

  # Setup note: each cart gets 1 unit of the vase and is then changed to 2, so this scenario
  # does not depend on stc-stock-01 (adding exactly the stock in one request).
  @negative
  Scenario: stc-chk-08-conflict changes nothing
    Given a cart named "A" containing product 6 with a quantity of 1
    And in cart "A" the quantity of product 6 is changed to 2
    And a cart named "B" containing product 1 with a quantity of 1
    And the cart "B" also contains product 6 with a quantity of 1
    And in cart "B" the quantity of product 6 is changed to 2
    When I check out cart "A"
    Then the response status is 201
    When I check out cart "B"
    Then the response status is 409
    And the stock of product 1 is 25
    And the cart "B" is still open

  @positive
  Scenario: stc-chk-09-get order
    Given an order for product 1 with a quantity of 2
    When I read the order
    Then the response status is 200
    And the order is the same as returned by the checkout

  @negative
  Scenario: stc-chk-10-get unknown order
    When I read the order "o999"
    Then the response status is 404
    And the response contains an error message