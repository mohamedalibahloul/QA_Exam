"""Steps for the cases about unclear points of the specification."""
import pytest
from pytest_bdd import given


@given("a product priced at exactly 3000 cents exists")
def product_priced_3000():
    # The catalogue has no product that gives a subtotal of exactly 3000, and the API cannot add products.
    pytest.skip("blocked: needs a product priced at 3000 cents in the catalogue (catalogue change or test product)")