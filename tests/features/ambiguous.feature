@amb
Feature: Unclear points of the specification
  These scenarios cover the places where SPEC.md is silent or unclear.
  Scenarios tagged @proposed use a PROPOSED expected result: a failure there must be
  discussed with the spec author before it is reported as a bug.

  Background:
    Given the shop API is running with its initial data

  # ---------- point 1: quantity limit (422) or stock (409), which one wins ----------
  @proposed @negative
  Scenario: stc-amb-01-limit and stock both broken on add
    Given an empty cart
    When I add product 4 with quantity 11
    Then the response status is 422
    And the cart is unchanged

  # Also depends on the cumulative limit (see stc-item-14): the 10-unit limit applies to the line.
  @proposed @negative
  Scenario: stc-amb-02-limit and stock both broken on line
    Given a cart containing product 4 with a quantity of 2
    When I add product 4 with quantity 9
    Then the response status is 422
    And the cart is unchanged

  @proposed @negative
  Scenario: stc-amb-03-limit and stock both broken on patch
    Given a cart containing product 4 with a quantity of 1
    When I change product 4 to quantity 11
    Then the response status is 422
    And the cart is unchanged

  # ---------- point 2: promo code case and spaces ----------
  @proposed @positive
  Scenario: stc-amb-04-promo lowercase
    Given a cart containing product 1 with a quantity of 2
    When I apply the promo code "welcome10"
    Then the response status is 200
    And the promo codes are "WELCOME10"

  @proposed @positive
  Scenario: stc-amb-05-promo surrounding spaces
    Given a cart containing product 1 with a quantity of 2
    When I apply the promo code " WELCOME10 "
    Then the response status is 200
    And the promo codes are "WELCOME10"

  @proposed @positive
  Scenario: stc-amb-06-promo mixed case no duplicate
    Given a cart containing product 1 with a quantity of 2
    And the promo code "WELCOME10" is applied
    When I apply the promo code "welcome10"
    Then the response status is 200
    And the promo codes are "WELCOME10"
    And the amounts are: subtotal 3990, discount 399, shipping 490, total 4081

  # ---------- point 3: does the 10-unit limit also apply to PATCH ----------
  @proposed @negative
  Scenario: stc-amb-07-patch above limit with enough stock
    Given a cart containing product 7 with a quantity of 1
    When I change product 7 to quantity 11
    Then the response status is 422
    And the cart is unchanged

  # ---------- point 4: FIVEOFF minimum of 3000 ----------
  @negative
  Scenario: stc-amb-08-fiveoff just below 3000
    Given a cart containing product 7 with a quantity of 2
    And the cart also contains product 2 with a quantity of 1
    When I apply the promo code "FIVEOFF"
    Then the response status is 422
    And the cart is unchanged

  @positive
  Scenario: stc-amb-09-fiveoff just above 3000
    Given a cart containing product 7 with a quantity of 4
    When I apply the promo code "FIVEOFF"
    Then the response status is 200
    And the amounts are: subtotal 3196, discount 500, shipping 490, total 3186

  @positive
  Scenario: stc-amb-10-fiveoff exactly 3000
    Given a product priced at exactly 3000 cents exists
    When I apply the promo code "FIVEOFF"
    Then the response status is 200

  # ---------- point 5: a fixed discount must never exceed the subtotal ----------
  @positive
  Scenario: stc-amb-11-fiveoff on emptied cart
    Given a cart containing product 1 with a quantity of 2
    And the promo code "FIVEOFF" is applied
    When I remove product 1
    Then the response status is 200
    And the amounts are: subtotal 0, discount 0, shipping 0, total 0

  @positive
  Scenario: stc-amb-12-fiveoff after reduction to small cart
    Given a cart containing product 1 with a quantity of 2
    And the promo code "FIVEOFF" is applied
    When I change product 1 to quantity 0
    And I add product 7 with quantity 1
    And I read the cart
    Then the amounts are: subtotal 799, discount 0, shipping 490, total 1289