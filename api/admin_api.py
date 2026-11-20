"""Test helper endpoint: POST /reset restores the initial data."""
from api.base_client import ApiResponse, BaseApiClient


class AdminApi:
    def __init__(self, client: BaseApiClient):
        self._client = client

    def reset(self) -> ApiResponse:
        return self._client.post("/reset")
