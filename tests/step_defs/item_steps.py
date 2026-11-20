"""Steps for adding, changing and removing cart lines."""
from pytest_bdd import given, parsers, then, when


def _snapshot(context, carts_api):
    """Remember the cart before the action, so 'the cart is unchanged' can compare."""
    context["cart_before"] = carts_api.get_cart(context["cart_id"]).body


# ---------- Given ----------
@given("an empty cart")
def empty_cart(context, carts_api):
    created = carts_api.create_cart()
    assert created.status_code == 201, f"setup failed, POST /carts: {created.status_code} {created.body}"
    context["cart_id"] = created.body["id"]


@given(parsers.parse("the cart also contains product {product_id:d} with a quantity of {quantity:d}"))
def cart_also_contains(context, carts_api, product_id, quantity):
    added = carts_api.add_item(context["cart_id"], product_id, quantity)
    assert added.status_code in (200, 201), f"setup failed, add item: {added.status_code} {added.body}"


# ---------- When ----------
@when(parsers.parse("I add product {product_id:d} with quantity {quantity:d}"))
def add_item(context, carts_api, product_id, quantity):
    _snapshot(context, carts_api)
    context["response"] = carts_api.add_item(context["cart_id"], product_id, quantity)


@when(parsers.parse('I add product {product_id:d} with quantity {quantity:d} to the cart "{cart_id}"'))
def add_item_to_cart(context, carts_api, product_id, quantity, cart_id):
    context["response"] = carts_api.add_item(cart_id, product_id, quantity)


@when(parsers.parse("I send this body to add an item: {body}"))
def add_item_raw(context, carts_api, body):
    _snapshot(context, carts_api)
    context["response"] = carts_api.add_item_raw(context["cart_id"], body)


@when(parsers.parse("I change product {product_id:d} to quantity {quantity:d}"))
def change_item(context, carts_api, product_id, quantity):
    _snapshot(context, carts_api)
    context["response"] = carts_api.update_item(context["cart_id"], product_id, quantity)


@when(parsers.parse("I send this body to change product {product_id:d}: {body}"))
def change_item_raw(context, carts_api, product_id, body):
    _snapshot(context, carts_api)
    context["response"] = carts_api.update_item_raw(context["cart_id"], product_id, body)


@when(parsers.parse("I remove product {product_id:d}"))
def remove_item(context, carts_api, product_id):
    _snapshot(context, carts_api)
    context["response"] = carts_api.remove_item(context["cart_id"], product_id)


# ---------- Then ----------
@then("the cart is unchanged")
def cart_unchanged(context, carts_api):
    assert carts_api.get_cart(context["cart_id"]).body == context["cart_before"]


@then(parsers.parse("the subtotal is {subtotal:d}"))
def check_subtotal(context, subtotal):
    assert context["response"].body["subtotalCents"] == subtotal


@then(parsers.parse("the line of product {product_id:d} has quantity {quantity:d} and a line total of {total:d}"))
def check_line(context, product_id, quantity, total):
    lines = [line for line in context["response"].body["items"] if line["productId"] == product_id]
    assert len(lines) == 1, f"expected exactly one line for product {product_id}, got {lines}"
    assert (lines[0]["quantity"], lines[0]["lineTotalCents"]) == (quantity, total)

@then(parsers.parse("the line of product {product_id:d} has a unit price of {price:d}"))
def check_unit_price(context, product_id, price):
    lines = [line for line in context["response"].body["items"] if line["productId"] == product_id]
    assert len(lines) == 1, f"expected exactly one line for product {product_id}, got {lines}"
    assert lines[0]["unitPriceCents"] == price