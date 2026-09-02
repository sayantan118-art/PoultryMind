from apps.api.config import Settings


def test_settings_parse_allowed_origins(monkeypatch):
    monkeypatch.setenv("DATABASE_URL", "postgresql://poultry_user:poultry_dev_pass@localhost:5432/poultry_dev")
    monkeypatch.setenv("REDIS_URL", "redis://localhost:6379/0")
    monkeypatch.setenv("JWT_SECRET_KEY", "test_secret_key_32_chars_long")
    monkeypatch.setenv("ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:5173")

    settings = Settings()

    assert settings.ALLOWED_ORIGINS == [
        "http://localhost:3000",
        "http://localhost:5173",
    ]
