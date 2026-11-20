"""Steps for stock rules and for scenarios with several named carts."""
from pytest_bdd import given, parsers, then, when


@given(parsers.parse('a cart named "{name}" containing product {product_id:d} with a quantity of {quantity:d}'))
def named_cart(context, carts_api, name, product_id, quantity):
    created = carts_api.create_cart()
    assert created.status_code == 201, f"setup failed, POST /carts: {created.status_code} {created.body}"
    cart_id = created.body["id"]
    context.setdefault("carts", {})[name] = cart_id
    added = carts_api.add_item(cart_id, product_id, quantity)
    assert added.status_code in (200, 201), f"setup failed, add item: {added.status_code} {added.body}"


@given(parsers.parse('in cart "{name}" the quantity of product {product_id:d} is changed to {quantity:d}'))
def change_in_named_cart(context, carts_api, name, product_id, quantity):
    changed = carts_api.update_item(context["carts"][name], product_id, quantity)
    assert changed.status_code == 200, f"setup failed, change quantity: {changed.status_code} {changed.body}"


@when(parsers.parse('I check out cart "{name}"'))
def check_out_named_cart(context, carts_api, name):
    context["response"] = carts_api.checkout(context["carts"][name])


@then(parsers.parse('the cart "{name}" is still open'))
def named_cart_still_open(context, carts_api, name):
    assert carts_api.get_cart(context["carts"][name]).body["status"] == "open"


@then(parsers.parse("the stock of product {product_id:d} is {stock:d}"))
def check_product_stock(products_api, product_id, stock):
    assert products_api.get_product(product_id).body["stock"] == stock