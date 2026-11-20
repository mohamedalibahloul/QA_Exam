"""Low-level HTTP client. The only place that knows about `requests`."""
import logging
from dataclasses import dataclass, field
from typing import Any

import requests

log = logging.getLogger(__name__)


@dataclass
class ApiResponse:
    """What tests see: status, parsed JSON body (or None), and timing."""

    status_code: int
    body: Any
    elapsed_ms: float
    headers: dict = field(default_factory=dict)


class BaseApiClient:
    def __init__(self, base_url: str, timeout: float = 5.0):
        self.base_url = base_url
        self.timeout = timeout
        self.session = requests.Session()

    def request(self, method: str, path: str, **kwargs) -> ApiResponse:
        url = f"{self.base_url}{path}"
        log.info("-> %s %s %s", method, url, kwargs.get("json", ""))
        raw = self.session.request(method, url, timeout=self.timeout, **kwargs)
        try:
            body = raw.json() if raw.content else None
        except ValueError:
            body = None
        response = ApiResponse(
            status_code=raw.status_code,
            body=body,
            elapsed_ms=raw.elapsed.total_seconds() * 1000,
            headers=dict(raw.headers),
        )
        log.info("<- %s %s (%.0f ms)", response.status_code, response.body, response.elapsed_ms)
        return response

    def get(self, path: str, **kwargs) -> ApiResponse:
        return self.request("GET", path, **kwargs)

    def post(self, path: str, **kwargs) -> ApiResponse:
        return self.request("POST", path, **kwargs)
