"""Fixtures: configuration, running server, API objects, and the per-scenario context."""
import pytest

from api.admin_api import AdminApi
from api.base_client import BaseApiClient
from api.carts_api import CartsApi
from api.orders_api import OrdersApi
from api.products_api import ProductsApi
from config.settings import load_settings


@pytest.fixture(scope="session")
def settings():
    return load_settings()


@pytest.fixture(scope="session")
def client(settings):
    return BaseApiClient(settings.base_url, settings.timeout)


@pytest.fixture
def admin_api(client):
    return AdminApi(client)


@pytest.fixture
def products_api(client):
    return ProductsApi(client)


@pytest.fixture
def carts_api(client):
    return CartsApi(client)


@pytest.fixture
def orders_api(client):
    return OrdersApi(client)


@pytest.fixture
def context():
    """Scenario state shared between steps (e.g. the last response). Fresh for every scenario."""
    return {}