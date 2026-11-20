"""Binds the Gherkin scenarios of item.feature to pytest tests."""
from pytest_bdd import scenarios

scenarios("item.feature")