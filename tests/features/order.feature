@ord
Feature: Order status
  As a shop owner
  I want orders to follow the allowed status changes only
  So that an order is never paid, shipped or cancelled by mistake

  Background:
    Given the shop API is running with its initial data

  @smoke @positive
  Scenario: stc-ord-01-pay pending order
    Given an order for product 1 with a quantity of 2
    When I pay the order
    Then the response status is 200
    And the response contains the order with status "paid"
    And the order status is "paid"

  @positive
  Scenario: stc-ord-02-ship paid order
    Given an order for product 1 with a quantity of 2
    And the order is paid
    When I ship the order
    Then the response status is 200
    And the response contains the order with status "shipped"
    And the order status is "shipped"

  @positive
  Scenario: stc-ord-03-cancel pending order
    Given an order for product 1 with a quantity of 2
    When I cancel the order
    Then the response status is 200
    And the response contains the order with status "cancelled"
    And the stock of product 1 is 25

  @positive
  Scenario: stc-ord-04-cancel paid order
    Given an order for product 1 with a quantity of 2
    And the order is paid
    When I cancel the order
    Then the response status is 200
    And the response contains the order with status "cancelled"
    And the stock of product 1 is 25

  @negative
  Scenario: stc-ord-05-ship unpaid order
    Given an order for product 1 with a quantity of 2
    When I ship the order
    Then the response status is 409
    And the order status is "pending_payment"

  @negative
  Scenario: stc-ord-06-pay twice
    Given an order for product 1 with a quantity of 2
    And the order is paid
    When I pay the order
    Then the response status is 409
    And the order status is "paid"

  @negative
  Scenario: stc-ord-07-pay shipped order
    Given an order for product 1 with a quantity of 2
    And the order is paid
    And the order is shipped
    When I pay the order
    Then the response status is 409
    And the order status is "shipped"

  @negative
  Scenario: stc-ord-08-cancel shipped order
    Given an order for product 1 with a quantity of 2
    And the order is paid
    And the order is shipped
    When I cancel the order
    Then the response status is 409
    And the order status is "shipped"
    And the stock of product 1 is 23

  @negative
  Scenario: stc-ord-09-change cancelled order
    Given an order for product 1 with a quantity of 2
    And the order is cancelled
    When I pay the order
    Then the response status is 409
    When I ship the order
    Then the response status is 409
    When I cancel the order
    Then the response status is 409
    And the order status is "cancelled"
    And the stock of product 1 is 25

  @negative
  Scenario: stc-ord-10-action on unknown order
    When I pay the order "o999"
    Then the response status is 404