@tot
Feature: Cart totals and shipping
  As a shopper
  I want the cart to show a correct subtotal, shipping and total
  So that I know exactly what I will pay

  Background:
    Given the shop API is running with its initial data

  @smoke @positive
  Scenario: stc-tot-01-subtotal multi lines
    Given a cart containing product 1 with a quantity of 2
    And the cart also contains product 2 with a quantity of 1
    When I read the cart
    Then the response status is 200
    And the amounts are: subtotal 5240, discount 0, shipping 0, total 5240

  @positive
  Scenario: stc-tot-02-shipping below threshold
    Given a cart containing product 2 with a quantity of 1
    When I read the cart
    Then the amounts are: subtotal 1250, discount 0, shipping 490, total 1740

  @positive
  Scenario: stc-tot-03-shipping at threshold
    Given a cart containing product 2 with a quantity of 4
    When I read the cart
    Then the amounts are: subtotal 5000, discount 0, shipping 0, total 5000

  @positive
  Scenario: stc-tot-04-shipping just below threshold
    Given a cart containing product 1 with a quantity of 1
    And the cart also contains product 3 with a quantity of 1
    When I read the cart
    Then the amounts are: subtotal 4485, discount 0, shipping 490, total 4975

  @positive
  Scenario: stc-tot-05-shipping uses subtotal after discount
    Given a cart containing product 1 with a quantity of 2
    And the cart also contains product 2 with a quantity of 1
    When I apply the promo code "WELCOME10"
    Then the response status is 200
    And the amounts are: subtotal 5240, discount 524, shipping 490, total 5206

  @positive
  Scenario: stc-tot-06-shipping empty cart
    Given an empty cart
    When I read the cart
    Then the amounts are: subtotal 0, discount 0, shipping 0, total 0

  @positive
  Scenario: stc-tot-07-totals recalculated on read
    Given a cart containing product 1 with a quantity of 2
    When I change product 1 to quantity 1
    And I read the cart
    Then the response status is 200
    And the amounts are: subtotal 1995, discount 0, shipping 490, total 2485

  @positive
  Scenario: stc-tot-08-line totals
    Given a cart containing product 3 with a quantity of 3
    When I read the cart
    Then the line of product 3 has a unit price of 2490
    And the line of product 3 has quantity 3 and a line total of 7470