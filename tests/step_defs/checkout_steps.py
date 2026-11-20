"""Steps for checkout."""
from pytest_bdd import given, parsers, then, when


# ---------- Given ----------
@given(parsers.parse('the cart "{name}" also contains product {product_id:d} with a quantity of {quantity:d}'))
def named_cart_also_contains(context, carts_api, name, product_id, quantity):
    added = carts_api.add_item(context["carts"][name], product_id, quantity)
    assert added.status_code in (200, 201), f"setup failed, add item: {added.status_code} {added.body}"


# ---------- When ----------
@when("I check out the cart")
def check_out_cart(context, carts_api):
    context["response"] = carts_api.checkout(context["cart_id"])


@when(parsers.parse('I check out the cart "{cart_id}"'))
def check_out_cart_by_id(context, carts_api, cart_id):
    context["response"] = carts_api.checkout(cart_id)


# ---------- Then ----------
@then("the order is waiting for payment")
def order_waiting_for_payment(context):
    assert context["response"].body["status"] == "pending_payment"


@then(parsers.parse("the order contains product {product_id:d} with a quantity of {quantity:d}"))
def order_contains_product(context, product_id, quantity):
    lines = [line for line in context["response"].body["items"] if line["productId"] == product_id]
    assert len(lines) == 1, f"expected exactly one line for product {product_id}, got {lines}"
    assert lines[0]["quantity"] == quantity


@then("the order amounts are the same as the cart amounts")
def order_amounts_equal_cart_amounts(context, carts_api):
    keys = ("subtotalCents", "discountCents", "shippingCents", "totalCents")
    order = context["response"].body
    cart = carts_api.get_cart(context["cart_id"]).body
    assert {k: order[k] for k in keys} == {k: cart[k] for k in keys}


@then(parsers.parse('the cart status is "{status}"'))
def check_cart_status(context, carts_api, status):
    assert carts_api.get_cart(context["cart_id"]).body["status"] == status


@then(parsers.parse('the order "{order_id}" does not exist'))
def order_does_not_exist(orders_api, order_id):
    assert orders_api.get_order(order_id).status_code == 404