"""Binds the Gherkin scenarios of stock.feature to pytest tests."""
from pytest_bdd import scenarios

scenarios("stock.feature")