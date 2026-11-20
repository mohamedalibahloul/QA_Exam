"""Binds the Gherkin scenarios of promo.feature to pytest tests."""
from pytest_bdd import scenarios

scenarios("promo.feature")