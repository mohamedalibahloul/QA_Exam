"""Binds the Gherkin scenarios of concurrency.feature to pytest tests."""
from pytest_bdd import scenarios

scenarios("concurrency.feature")