"""Binds the Gherkin scenarios of tot.feature to pytest tests."""
from pytest_bdd import scenarios

scenarios("tot.feature")