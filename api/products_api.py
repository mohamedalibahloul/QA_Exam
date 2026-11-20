"""Catalogue endpoints: GET /products and GET /products/:id."""
from api.base_client import ApiResponse, BaseApiClient


class ProductsApi:
    def __init__(self, client: BaseApiClient):
        self._client = client

    def list_products(self) -> ApiResponse:
        return self._client.get("/products")

    def get_product(self, product_id: int) -> ApiResponse:
        return self._client.get(f"/products/{product_id}")
