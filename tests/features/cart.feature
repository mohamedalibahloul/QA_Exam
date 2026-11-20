@cart
Feature: Cart creation and reading
  As a shopper
  I want to create a cart and read it back
  So that I can see what I am about to buy and how much it costs

  Background:
    Given the shop API is running with its initial data

  @smoke @positive
  Scenario: stc-cart-01-create empty cart
    When I create a cart
    Then the response status is 201
    And the cart has an id
    And the cart is open and empty
    And the amounts are: subtotal 0, discount 0, shipping 0, total 0

  @positive
  Scenario: stc-cart-02-get existing cart
    Given a cart containing product 1 with a quantity of 1
    When I read the cart
    Then the response status is 200
    And the cart has 1 product line
    And the amounts are: subtotal 1995, discount 0, shipping 490, total 2485
    And the cart content is the same as right after adding the product

  @negative
  Scenario: stc-cart-03-get unknown cart
    When I read the cart "c999"
    Then the response status is 404
    And the response contains an error message

  @positive
  Scenario: stc-cart-04-cart view fields
    Given a cart containing product 1 with a quantity of 1
    When I read the cart
    Then the response status is 200
    And the cart has all the documented fields with the right types