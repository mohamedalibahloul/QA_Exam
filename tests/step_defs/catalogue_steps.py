import json

from pytest_bdd import parsers, then, when

from config.settings import PROJECT_ROOT

PRODUCT_FIELDS = {"id": int, "name": str, "priceCents": int, "stock": int}
INITIAL_CATALOGUE = json.loads((PROJECT_ROOT / "data" / "initial_catalogue.json").read_text())


@when("I request the list of products")
def request_product_list(context, products_api):
    context["response"] = products_api.list_products()


@when(parsers.parse("I request the product with id {product_id:d}"))
def request_product(context, products_api, product_id):
    context["response"] = products_api.get_product(product_id)


@then(parsers.parse("the catalogue contains {count:d} products"))
def check_catalogue_size(context, count):
    body = context["response"].body
    assert isinstance(body, list), f"expected a JSON array, got {type(body).__name__}"
    assert len(body) == count, f"expected {count} products, got {len(body)}"


@then("every product has an id, a name, a price in cents and a stock with the right types")
def check_product_shape(context):
    for product in context["response"].body:
        for name, expected_type in PRODUCT_FIELDS.items():
            assert name in product, f"product {product}: missing field '{name}'"
            assert type(product[name]) is expected_type, f"product {product['id']}: '{name}' should be {expected_type.__name__}, got {product[name]!r}"

@then("the products match the initial catalogue")
def check_catalogue_content(context):
    actual = sorted(context["response"].body, key=lambda p: p["id"])
    assert actual == INITIAL_CATALOGUE


@then(parsers.parse('the product is "{name}" priced {price:d} cents with a stock of {stock:d}'))
def check_single_product(context, name, price, stock):
    product = context["response"].body
    assert product == {"id": 1, "name": name, "priceCents": price, "stock": stock}