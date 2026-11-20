"""Binds the Gherkin scenarios of catalogue.feature to pytest tests."""
from pytest_bdd import scenarios

scenarios("catalogue.feature")
