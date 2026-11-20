@promo
Feature: Promo codes
  As a shopper
  I want to apply promo codes to my cart
  So that I get the discount or the free shipping I am entitled to

  Background:
    Given the shop API is running with its initial data

  # ---------- WELCOME10 ----------
  @smoke @positive
  Scenario: stc-promo-01-welcome10 valid
    Given a cart containing product 1 with a quantity of 2
    When I apply the promo code "WELCOME10"
    Then the response status is 200
    And the promo codes are "WELCOME10"
    And the amounts are: subtotal 3990, discount 399, shipping 490, total 4081

  @positive
  Scenario: stc-promo-02-percent rounded half up
    Given a cart containing product 1 with a quantity of 1
    When I apply the promo code "WELCOME10"
    Then the response status is 200
    And the amounts are: subtotal 1995, discount 200, shipping 490, total 2285

  # ---------- FIVEOFF ----------
  @positive
  Scenario: stc-promo-03-fiveoff valid
    Given a cart containing product 1 with a quantity of 2
    When I apply the promo code "FIVEOFF"
    Then the response status is 200
    And the amounts are: subtotal 3990, discount 500, shipping 490, total 3980

  @negative
  Scenario: stc-promo-04-fiveoff below minimum
    Given a cart containing product 2 with a quantity of 2
    When I apply the promo code "FIVEOFF"
    Then the response status is 422
    And the cart is unchanged

  @positive
  Scenario: stc-promo-05-fiveoff condition lost
    Given a cart containing product 1 with a quantity of 2
    And the promo code "FIVEOFF" is applied
    When I change product 1 to quantity 1
    And I read the cart
    Then the amounts are: subtotal 1995, discount 0, shipping 490, total 2485

  @positive
  Scenario: stc-promo-06-fiveoff condition back
    Given a cart containing product 1 with a quantity of 2
    And the promo code "FIVEOFF" is applied
    When I change product 1 to quantity 1
    And I change product 1 to quantity 2
    And I read the cart
    Then the amounts are: subtotal 3990, discount 500, shipping 490, total 3980

  # ---------- FREESHIP ----------
  @positive
  Scenario: stc-promo-07-freeship
    Given a cart containing product 2 with a quantity of 1
    When I apply the promo code "FREESHIP"
    Then the response status is 200
    And the amounts are: subtotal 1250, discount 0, shipping 0, total 1250

  # Setup note: 2 candles (3990) instead of 1 (1995), so the 10% is exact (399).
  # With 1 candle the discount is 199.5 and this scenario would also fail on the
  # rounding bug (already covered by stc-promo-02) instead of testing FREESHIP only.
  @positive
  Scenario: stc-promo-08-discount plus freeship
    Given a cart containing product 1 with a quantity of 2
    And the promo code "WELCOME10" is applied
    When I apply the promo code "FREESHIP"
    Then the response status is 200
    And the promo codes are "WELCOME10, FREESHIP"
    And the amounts are: subtotal 3990, discount 399, shipping 0, total 3591

  # ---------- combining and repeating codes ----------
  @negative
  Scenario: stc-promo-09-second discount refused
    Given a cart containing product 1 with a quantity of 2
    And the promo code "WELCOME10" is applied
    When I apply the promo code "FIVEOFF"
    Then the response status is 409
    And the cart is unchanged

  @negative
  Scenario: stc-promo-10-second discount refused reverse
    Given a cart containing product 1 with a quantity of 2
    And the promo code "FIVEOFF" is applied
    When I apply the promo code "WELCOME10"
    Then the response status is 409
    And the cart is unchanged

  @positive
  Scenario: stc-promo-11-same code twice
    Given a cart containing product 1 with a quantity of 2
    And the promo code "WELCOME10" is applied
    When I apply the promo code "WELCOME10"
    Then the response status is 200
    And the promo codes are "WELCOME10"
    And the amounts are: subtotal 3990, discount 399, shipping 490, total 4081

  # ---------- invalid requests ----------
  @negative
  Scenario: stc-promo-12-unknown code
    Given a cart containing product 1 with a quantity of 1
    When I apply the promo code "NOPE"
    Then the response status is 404
    And the cart is unchanged

  @negative
  Scenario: stc-promo-13-empty code
    Given a cart containing product 1 with a quantity of 1
    When I send this body to apply a promo code: {"code": ""}
    Then the response status is 400
    And the cart is unchanged

  @negative
  Scenario Outline: stc-promo-14-code wrong type or missing
    Given a cart containing product 1 with a quantity of 1
    When I send this body to apply a promo code: <body>
    Then the response status is 400
    And the cart is unchanged

    Examples:
      | body            |
      | {}              |
      | {"code": 123}   |

  @negative
  Scenario: stc-promo-15-unknown cart
    When I apply the promo code "WELCOME10" to the cart "c999"
    Then the response status is 404

  @negative
  Scenario: stc-promo-16-promo on checked out cart
    Given a cart containing product 1 with a quantity of 1
    And the cart is checked out
    When I apply the promo code "WELCOME10"
    Then the response status is 409

  # ---------- SUMMER25 (depends on the date of the machine running the API) ----------
  @negative
  Scenario: stc-promo-17-summer25 expired
    Given a cart containing product 1 with a quantity of 2
    When I apply the promo code "SUMMER25"
    Then the response status is 422
    And the cart is unchanged

  @positive
  Scenario: stc-promo-18-summer25 valid
    Given the server clock is set to "2026-08-01 12:00 UTC"
    And a cart containing product 1 with a quantity of 2
    When I apply the promo code "SUMMER25"
    Then the response status is 200
    And the amounts are: subtotal 3990, discount 998, shipping 490, total 3482

  @positive
  Scenario: stc-promo-19-summer25 last day
    Given the server clock is set to "2026-08-31 23:59 UTC"
    And a cart containing product 1 with a quantity of 2
    When I apply the promo code "SUMMER25"
    Then the response status is 200

  @negative
  Scenario: stc-promo-20-summer25 day after
    Given the server clock is set to "2026-09-01 00:00 UTC"
    And a cart containing product 1 with a quantity of 2
    When I apply the promo code "SUMMER25"
    Then the response status is 422

  # ---------- discount cap ----------
  @positive
  Scenario: stc-promo-21-discount capped at subtotal
    Given a cart containing product 2 with a quantity of 3
    And the promo code "FIVEOFF" is applied
    When I change product 2 to quantity 1
    Then the discount is not above the subtotal and the total is not negative
    When I remove product 2
    Then the discount is not above the subtotal and the total is not negative