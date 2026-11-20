@prod
Feature: Product catalogue
  As a shopper
  I want to browse the catalogue
  So that I can see the products, their prices and their stock

  Background:
    Given the shop API is running with its initial data

  @smoke @positive
  Scenario: stc-prod-01-list catalogue
    When I request the list of products
    Then the response status is 200
    And the catalogue contains 8 products
    And every product has an id, a name, a price in cents and a stock with the right types
    And the products match the initial catalogue

  @positive
  Scenario: stc-prod-02-get existing product
    When I request the product with id 1
    Then the response status is 200
    And the product is "Amber Candle" priced 1995 cents with a stock of 25

  @negative
  Scenario: stc-prod-03-get unknown product
    When I request the product with id 999
    Then the response status is 404
    And the response contains an error message
