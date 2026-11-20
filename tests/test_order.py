"""Binds the Gherkin scenarios of order.feature to pytest tests."""
from pytest_bdd import scenarios

scenarios("order.feature")