import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

os.environ.setdefault("DATABASE_URL", "postgresql://poultry_user:poultry_dev_pass@localhost:5432/poultry_dev")
os.environ.setdefault("REDIS_URL", "redis://localhost:6379/0")
os.environ.setdefault("JWT_SECRET_KEY", "test_secret_key_32_chars_long")
os.environ.setdefault("ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:5173")
os.environ.setdefault("ENVIRONMENT", "test")

import pytest
from fastapi.testclient import TestClient

from apps.api.main import app


@pytest.fixture
def client():
    return TestClient(app)
