"""Binds the Gherkin scenarios of cart.feature to pytest tests."""
from pytest_bdd import scenarios

scenarios("cart.feature")