import os
from dataclasses import dataclass
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent


@dataclass(frozen=True)
class Settings:
    base_url: str
    timeout: float


def load_settings() -> Settings:
    return Settings(
        base_url=os.getenv("BASE_URL", "http://localhost:3002").rstrip("/"),
        timeout=float(os.getenv("API_TIMEOUT", "5")),
    )