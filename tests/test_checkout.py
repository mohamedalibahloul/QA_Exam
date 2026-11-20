"""Binds the Gherkin scenarios of checkout.feature to pytest tests."""
from pytest_bdd import scenarios

scenarios("checkout.feature")