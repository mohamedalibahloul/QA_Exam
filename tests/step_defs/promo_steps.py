"""Steps for promo codes."""

import pytest
from pytest_bdd import given, parsers, then, when


def _snapshot(context, carts_api):
    """Remember the cart before the action, so 'the cart is unchanged' can compare."""
    context["cart_before"] = carts_api.get_cart(context["cart_id"]).body


# ---------- Given ----------
@given(parsers.parse('the promo code "{code}" is applied'))
def promo_already_applied(context, carts_api, code):
    response = carts_api.apply_promo(context["cart_id"], code)
    assert response.status_code == 200, f"setup failed, apply promo: {response.status_code} {response.body}"


@given("the cart is checked out")
def cart_checked_out(context, carts_api):
    response = carts_api.checkout(context["cart_id"])
    assert response.status_code == 201, f"setup failed, checkout: {response.status_code} {response.body}"


@given(parsers.parse('the server clock is set to "{moment}"'))
def server_clock(moment):
    # The API reads the real clock of the machine it runs on: this cannot be done from the tests.
    pytest.skip(f"blocked: needs the server clock set to {moment} (for example with faketime)")


# ---------- When ----------
@when(parsers.re(r'I apply the promo code "(?P<code>[^"]+)"$'))
def apply_promo(context, carts_api, code):
    _snapshot(context, carts_api)
    context["response"] = carts_api.apply_promo(context["cart_id"], code)


@when(parsers.parse('I apply the promo code "{code}" to the cart "{cart_id}"'))
def apply_promo_to_cart(context, carts_api, code, cart_id):
    context["response"] = carts_api.apply_promo(cart_id, code)


@when(parsers.parse("I send this body to apply a promo code: {body}"))
def apply_promo_raw(context, carts_api, body):
    _snapshot(context, carts_api)
    context["response"] = carts_api.apply_promo_raw(context["cart_id"], body)


# ---------- Then ----------
@then(parsers.parse('the promo codes are "{codes}"'))
def check_promo_codes(context, codes):
    expected = sorted(code.strip() for code in codes.split(","))
    assert sorted(context["response"].body["promoCodes"]) == expected


@then("the discount is not above the subtotal and the total is not negative")
def check_discount_cap(context, carts_api):
    cart = carts_api.get_cart(context["cart_id"]).body
    assert cart["discountCents"] <= cart["subtotalCents"], cart
    assert cart["totalCents"] >= 0, cart