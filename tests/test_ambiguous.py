"""Binds the Gherkin scenarios of ambiguous.feature to pytest tests."""
from pytest_bdd import scenarios

scenarios("ambiguous.feature")