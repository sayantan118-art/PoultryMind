# apps/api/config.py
from pathlib import Path

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=(
            ".env",
            str(Path(__file__).resolve().parent / ".env"),
            str(Path(__file__).resolve().parents[2] / ".env"),
        ),
        case_sensitive=True,
        extra="ignore",
    )

    # DATABASE
    DATABASE_URL: str = Field(..., min_length=20)
    DATABASE_POOL_SIZE: int = 10
    DATABASE_MAX_OVERFLOW: int = 20

    # AWS
    AWS_ACCESS_KEY_ID: str = ""
    AWS_SECRET_ACCESS_KEY: str = ""
    AWS_REGION: str = "ap-south-1"

    # AWS COGNITO
    COGNITO_USER_POOL_ID: str = ""
    COGNITO_CLIENT_ID: str = ""
    COGNITO_REGION: str = "ap-south-1"

    # JWT
    JWT_SECRET_KEY: str = Field(..., min_length=32)
    JWT_ALGORITHM: str = "HS256"

    # REDIS
    REDIS_URL: str = Field(..., min_length=10)

    # APP CONFIG
    ENVIRONMENT: str = "development"
    LOG_LEVEL: str = "DEBUG"
    APP_PORT: int = 8000

    ALLOWED_ORIGINS: list[str] = Field(
        default_factory=lambda: [
            "http://localhost:5173",
            "http://localhost:8081",
            "http://localhost:3000",
        ]
    )

    @field_validator("ALLOWED_ORIGINS", mode="before")
    @classmethod
    def parse_allowed_origins(cls, value):
        if isinstance(value, str):
            return [origin.strip() for origin in value.split(",") if origin.strip()]
        return value


settings = Settings()

