"""Root conftest: registers the step-definition modules so every feature can use them."""
pytest_plugins = [
    "tests.step_defs.common_steps",
    "tests.step_defs.catalogue_steps",
    "tests.step_defs.cart_steps",
    "tests.step_defs.item_steps",
    "tests.step_defs.stock_steps",
    "tests.step_defs.promo_steps",
    "tests.step_defs.checkout_steps",
    "tests.step_defs.order_steps",
    "tests.step_defs.concurrency_steps",
    "tests.step_defs.amb_steps",
]