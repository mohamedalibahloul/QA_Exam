"""Steps for parallel requests."""
import threading
from concurrent.futures import ThreadPoolExecutor

from pytest_bdd import given, parsers, then, when


# ---------- Given ----------
@given(parsers.parse("{count:d} carts each containing product {product_id:d} with a quantity of {quantity:d}"))
def several_carts(context, carts_api, count, product_id, quantity):
    context["carts"] = {}
    for number in range(1, count + 1):
        created = carts_api.create_cart()
        assert created.status_code == 201, f"setup failed, POST /carts: {created.status_code} {created.body}"
        cart_id = created.body["id"]
        added = carts_api.add_item(cart_id, product_id, quantity)
        assert added.status_code in (200, 201), f"setup failed, add item: {added.status_code} {added.body}"
        context["carts"][f"cart{number}"] = cart_id


# ---------- When ----------
@when("I check out all the carts at the same time")
def check_out_all_at_once(context, carts_api):
    cart_ids = list(context["carts"].values())
    barrier = threading.Barrier(len(cart_ids))  # every request waits here, then all start together

    def checkout(cart_id):
        barrier.wait()
        return carts_api.checkout(cart_id)

    with ThreadPoolExecutor(max_workers=len(cart_ids)) as pool:
        context["responses"] = list(pool.map(checkout, cart_ids))


# ---------- Then ----------
@then(parsers.parse("exactly {created:d} checkouts succeed and {refused:d} are refused with status 409"))
def check_parallel_results(context, created, refused):
    statuses = sorted(response.status_code for response in context["responses"])
    expected = sorted([201] * created + [409] * refused)
    assert statuses == expected, f"expected statuses {expected}, got {statuses}"