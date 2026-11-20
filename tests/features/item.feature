@item
Feature: Cart lines: add, change and remove products
  As a shopper
  I want to add, change and remove products in my cart
  So that the cart contains exactly what I want to buy

  Background:
    Given the shop API is running with its initial data

  # ---------- add ----------
  @smoke @positive
  Scenario: stc-item-01-add new product
    Given an empty cart
    When I add product 1 with quantity 2
    Then the response status is 201
    And the line of product 1 has quantity 2 and a line total of 3990
    And the subtotal is 3990

  @positive
  Scenario: stc-item-02-add existing product increases line
    Given a cart containing product 1 with a quantity of 2
    When I add product 1 with quantity 3
    Then the response status is 200
    And the cart has 1 product line
    And the line of product 1 has quantity 5 and a line total of 9975

  @positive
  Scenario: stc-item-03-add second product creates line
    Given a cart containing product 1 with a quantity of 1
    When I add product 2 with quantity 1
    Then the response status is 201
    And the cart has 2 product lines
    And the subtotal is 3245

  # ---------- invalid quantity or body ----------
  @negative
  Scenario: stc-item-04-add quantity zero
    Given an empty cart
    When I add product 1 with quantity 0
    Then the response status is 400
    And the response contains an error message
    And the cart is unchanged

  @negative
  Scenario: stc-item-05-add negative quantity
    Given an empty cart
    When I add product 1 with quantity -1
    Then the response status is 400
    And the cart is unchanged

  @negative
  Scenario: stc-item-06-add decimal quantity
    Given an empty cart
    When I send this body to add an item: {"productId": 1, "quantity": 1.5}
    Then the response status is 400
    And the cart is unchanged

  @negative
  Scenario: stc-item-07-add string quantity
    Given an empty cart
    When I send this body to add an item: {"productId": 1, "quantity": "2"}
    Then the response status is 400
    And the cart is unchanged

  @negative
  Scenario Outline: stc-item-08-add missing fields
    Given an empty cart
    When I send this body to add an item: <body>
    Then the response status is 400
    And the cart is unchanged

    Examples:
      | body                |
      | {"productId": 1}    |
      | {"quantity": 1}     |

  @negative
  Scenario: stc-item-09-add unknown product
    Given an empty cart
    When I add product 999 with quantity 1
    Then the response status is 404
    And the cart is unchanged

  @negative
  Scenario: stc-item-10-add to unknown cart
    When I add product 1 with quantity 1 to the cart "c999"
    Then the response status is 404

  @negative
  Scenario: stc-item-11-add invalid json
    Given an empty cart
    When I send this body to add an item: {not json
    Then the response status is 400
    And the response contains an error message

  # ---------- limit of 10 units per product ----------
  @positive
  Scenario: stc-item-12-limit exactly 10 units
    Given an empty cart
    When I add product 7 with quantity 10
    Then the response status is 201
    And the line of product 7 has quantity 10 and a line total of 7990

  @negative
  Scenario: stc-item-13-limit 11 units one request
    Given an empty cart
    When I add product 7 with quantity 11
    Then the response status is 422
    And the cart is unchanged

  @negative
  Scenario: stc-item-14-limit cumulative on line
    Given a cart containing product 7 with a quantity of 6
    When I add product 7 with quantity 5
    Then the response status is 422
    And the cart is unchanged

  @positive
  Scenario: stc-item-15-limit per product
    Given a cart containing product 7 with a quantity of 10
    When I add product 2 with quantity 10
    Then the response status is 201
    And the cart has 2 product lines
    And the line of product 7 has quantity 10 and a line total of 7990
    And the line of product 2 has quantity 10 and a line total of 12500

  # ---------- change quantity (PATCH) ----------
  @positive
  Scenario: stc-item-16-patch quantity
    Given a cart containing product 1 with a quantity of 2
    When I change product 1 to quantity 4
    Then the response status is 200
    And the line of product 1 has quantity 4 and a line total of 7980
    And the subtotal is 7980

  @positive
  Scenario: stc-item-17-patch zero removes line
    Given a cart containing product 1 with a quantity of 2
    And the cart also contains product 2 with a quantity of 1
    When I change product 1 to quantity 0
    Then the response status is 200
    And the cart has 1 product line
    And the subtotal is 1250

  @negative
  Scenario: stc-item-18-patch negative
    Given a cart containing product 1 with a quantity of 2
    When I change product 1 to quantity -1
    Then the response status is 400
    And the cart is unchanged

  @negative
  Scenario: stc-item-19-patch decimal
    Given a cart containing product 1 with a quantity of 2
    When I send this body to change product 1: {"quantity": 2.5}
    Then the response status is 400
    And the cart is unchanged

  @negative
  Scenario: stc-item-20-patch above limit
    Given a cart containing product 7 with a quantity of 1
    When I change product 7 to quantity 11
    Then the response status is 422
    And the cart is unchanged

  @positive
  Scenario: stc-item-21-patch exactly limit
    Given a cart containing product 7 with a quantity of 1
    When I change product 7 to quantity 10
    Then the response status is 200
    And the line of product 7 has quantity 10 and a line total of 7990

  @negative
  Scenario: stc-item-22-patch product not in cart
    Given a cart containing product 1 with a quantity of 1
    When I change product 2 to quantity 1
    Then the response status is 404
    And the cart is unchanged

  # ---------- delete ----------
  @positive
  Scenario: stc-item-23-delete line
    Given a cart containing product 1 with a quantity of 1
    And the cart also contains product 2 with a quantity of 1
    When I remove product 1
    Then the response status is 200
    And the cart has 1 product line
    And the amounts are: subtotal 1250, discount 0, shipping 490, total 1740

  @positive
  Scenario: stc-item-24-delete last line
    Given a cart containing product 1 with a quantity of 1
    When I remove product 1
    Then the response status is 200
    And the cart has 0 product lines
    And the amounts are: subtotal 0, discount 0, shipping 0, total 0

  @negative
  Scenario: stc-item-25-delete line not in cart
    Given a cart containing product 1 with a quantity of 1
    When I remove product 2
    Then the response status is 404
    And the cart is unchanged