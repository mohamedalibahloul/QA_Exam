"""Cart endpoints: POST /carts, GET /carts/:id, POST /carts/:id/items."""
from api.base_client import ApiResponse, BaseApiClient


class CartsApi:
    def __init__(self, client: BaseApiClient):
        self._client = client

    def create_cart(self) -> ApiResponse:
        return self._client.post("/carts")

    def get_cart(self, cart_id: str) -> ApiResponse:
        return self._client.get(f"/carts/{cart_id}")

    def add_item(self, cart_id: str, product_id: int, quantity: int) -> ApiResponse:
        return self._client.post(f"/carts/{cart_id}/items", json={"productId": product_id, "quantity": quantity})

    def add_item_raw(self, cart_id: str, body: str) -> ApiResponse:
        """Send the body exactly as written (to test wrong types, missing fields, broken JSON)."""
        return self._client.post(f"/carts/{cart_id}/items", data=body, headers={"Content-Type": "application/json"})

    def update_item(self, cart_id: str, product_id: int, quantity: int) -> ApiResponse:
        return self._client.request("PATCH", f"/carts/{cart_id}/items/{product_id}", json={"quantity": quantity})

    def update_item_raw(self, cart_id: str, product_id: int, body: str) -> ApiResponse:
        return self._client.request(
            "PATCH", f"/carts/{cart_id}/items/{product_id}", data=body, headers={"Content-Type": "application/json"}
        )

    def remove_item(self, cart_id: str, product_id: int) -> ApiResponse:
        return self._client.request("DELETE", f"/carts/{cart_id}/items/{product_id}")

    def checkout(self, cart_id: str) -> ApiResponse:
        return self._client.post(f"/carts/{cart_id}/checkout")
    
    def apply_promo(self, cart_id: str, code: str) -> ApiResponse:
        return self._client.post(f"/carts/{cart_id}/promo", json={"code": code})

    def apply_promo_raw(self, cart_id: str, body: str) -> ApiResponse:
        return self._client.post(f"/carts/{cart_id}/promo", data=body, headers={"Content-Type": "application/json"})