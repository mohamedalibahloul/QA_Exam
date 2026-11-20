"""Order endpoints: GET /orders/:id and POST /orders/:id/pay|ship|cancel."""
from api.base_client import ApiResponse, BaseApiClient


class OrdersApi:
    def __init__(self, client: BaseApiClient):
        self._client = client

    def get_order(self, order_id: str) -> ApiResponse:
        return self._client.get(f"/orders/{order_id}")

    def pay(self, order_id: str) -> ApiResponse:
        return self._client.post(f"/orders/{order_id}/pay")

    def ship(self, order_id: str) -> ApiResponse:
        return self._client.post(f"/orders/{order_id}/ship")

    def cancel(self, order_id: str) -> ApiResponse:
        return self._client.post(f"/orders/{order_id}/cancel")