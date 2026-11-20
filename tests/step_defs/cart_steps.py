"""Steps specific to the cart features."""
from pytest_bdd import given, parsers, then, when



CART_FIELDS = {"id": str, "status": str, "promoCodes": list, "items": list,
               "subtotalCents": int, "discountCents": int, "shippingCents": int, "totalCents": int}
CART_LINE_FIELDS = {"productId": int, "name": str, "unitPriceCents": int, "quantity": int, "lineTotalCents": int}

@given(parsers.parse("a cart containing product {product_id:d} with a quantity of {quantity:d}"))
def cart_with_product(context, carts_api, product_id, quantity):
    created = carts_api.create_cart()
    assert created.status_code == 201, f"setup failed, POST /carts: {created.status_code} {created.body}"
    context["cart_id"] = created.body["id"]
    added = carts_api.add_item(context["cart_id"], product_id, quantity)
    assert added.status_code in (200, 201), f"setup failed, add item: {added.status_code} {added.body}"
    context["cart_after_add"] = added.body


@when("I create a cart")
def create_cart(context, carts_api):
    context["response"] = carts_api.create_cart()


@when("I read the cart")
def read_cart(context, carts_api):
    context["response"] = carts_api.get_cart(context["cart_id"])


@when(parsers.parse('I read the cart "{cart_id}"'))
def read_cart_by_id(context, carts_api, cart_id):
    context["response"] = carts_api.get_cart(cart_id)


@then("the cart has an id")
def check_cart_id(context):
    cart_id = context["response"].body.get("id")
    assert isinstance(cart_id, str) and cart_id, f"expected a non-empty id, got {cart_id!r}"


@then("the cart is open and empty")
def check_cart_open_and_empty(context):
    cart = context["response"].body
    assert cart["status"] == "open"
    assert cart["items"] == []
    assert cart["promoCodes"] == []


@then(parsers.parse("the amounts are: subtotal {subtotal:d}, discount {discount:d}, shipping {shipping:d}, total {total:d}"))
def check_amounts(context, subtotal, discount, shipping, total):
    cart = context["response"].body
    actual = {k: cart[k] for k in ("subtotalCents", "discountCents", "shippingCents", "totalCents")}
    expected = {"subtotalCents": subtotal, "discountCents": discount, "shippingCents": shipping, "totalCents": total}
    assert actual == expected


@then(parsers.re(r"the cart has (?P<count>\d+) product lines?"), converters={"count": int})
def check_line_count(context, count):
    assert len(context["response"].body["items"]) == count


@then("the cart content is the same as right after adding the product")
def check_same_as_after_add(context):
    assert context["response"].body == context["cart_after_add"]

@then("the cart has all the documented fields with the right types")
def check_cart_fields(context):
    cart = context["response"].body
    for name, expected_type in CART_FIELDS.items():
        assert name in cart, f"cart: missing field '{name}'"
        assert type(cart[name]) is expected_type, f"cart: '{name}' should be {expected_type.__name__}, got {cart[name]!r}"
    assert cart["status"] in ("open", "checked_out"), f"unexpected status {cart['status']!r}"
    for line in cart["items"]:
        for name, expected_type in CART_LINE_FIELDS.items():
            assert name in line, f"cart line: missing field '{name}'"
            assert type(line[name]) is expected_type, f"cart line: '{name}' should be {expected_type.__name__}, got {line[name]!r}"

@when(parsers.parse('I apply the promo code "{code}"'))
def apply_promo(context, carts_api, code):
    context["response"] = carts_api.apply_promo(context["cart_id"], code)

@when(parsers.parse('I apply the promo code "{code}"'))
def apply_promo(context, carts_api, code):
    context["response"] = carts_api.apply_promo(context["cart_id"], code)