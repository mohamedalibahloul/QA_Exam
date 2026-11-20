"""Steps for order status changes."""
from pytest_bdd import given, parsers, then, when


# ---------- Given ----------
@given(parsers.parse("an order for product {product_id:d} with a quantity of {quantity:d}"))
def order_for_product(context, carts_api, product_id, quantity):
    created = carts_api.create_cart()
    assert created.status_code == 201, f"setup failed, POST /carts: {created.status_code} {created.body}"
    context["cart_id"] = created.body["id"]
    added = carts_api.add_item(context["cart_id"], product_id, quantity)
    assert added.status_code in (200, 201), f"setup failed, add item: {added.status_code} {added.body}"
    checked = carts_api.checkout(context["cart_id"])
    assert checked.status_code == 201, f"setup failed, checkout: {checked.status_code} {checked.body}"
    context["order"] = checked.body
    context["order_id"] = checked.body["id"]


@given("the order is paid")
def order_is_paid(context, orders_api):
    response = orders_api.pay(context["order_id"])
    assert response.status_code == 200, f"setup failed, pay: {response.status_code} {response.body}"


@given("the order is shipped")
def order_is_shipped(context, orders_api):
    response = orders_api.ship(context["order_id"])
    assert response.status_code == 200, f"setup failed, ship: {response.status_code} {response.body}"


@given("the order is cancelled")
def order_is_cancelled(context, orders_api):
    response = orders_api.cancel(context["order_id"])
    assert response.status_code == 200, f"setup failed, cancel: {response.status_code} {response.body}"


# ---------- When ----------
@when("I read the order")
def read_order(context, orders_api):
    context["response"] = orders_api.get_order(context["order_id"])


@when(parsers.parse('I read the order "{order_id}"'))
def read_order_by_id(context, orders_api, order_id):
    context["response"] = orders_api.get_order(order_id)


@when("I pay the order")
def pay_order(context, orders_api):
    context["response"] = orders_api.pay(context["order_id"])


@when(parsers.parse('I pay the order "{order_id}"'))
def pay_order_by_id(context, orders_api, order_id):
    context["response"] = orders_api.pay(order_id)


@when("I ship the order")
def ship_order(context, orders_api):
    context["response"] = orders_api.ship(context["order_id"])


@when("I cancel the order")
def cancel_order(context, orders_api):
    context["response"] = orders_api.cancel(context["order_id"])


# ---------- Then ----------
@then(parsers.parse('the order status is "{status}"'))
def check_order_status(context, orders_api, status):
    assert orders_api.get_order(context["order_id"]).body["status"] == status


@then(parsers.parse('the response contains the order with status "{status}"'))
def check_response_order_status(context, status):
    assert context["response"].body["status"] == status


@then("the order is the same as returned by the checkout")
def order_same_as_checkout(context):
    assert context["response"].body == context["order"]