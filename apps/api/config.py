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
    DATABASE_ECHO: bool = False

    # AWS
    AWS_ACCESS_KEY_ID: str = ""
    AWS_SECRET_ACCESS_KEY: str = ""
    AWS_REGION: str = "ap-south-1"
    AWS_ACCOUNT_ID: str = ""
    USE_AWS_SECRETS_MANAGER: bool = False
    AWS_SECRETS_REGION: str = "ap-south-1"

    # AWS COGNITO
    COGNITO_USER_POOL_ID: str = ""
    COGNITO_CLIENT_ID: str = ""
    COGNITO_REGION: str = "ap-south-1"
    COGNITO_DOMAIN: str = ""

    # JWT
    JWT_SECRET_KEY: str = Field(..., min_length=32)
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRATION_HOURS: int = 24
    JWT_REFRESH_EXPIRATION_DAYS: int = 30

    # REDIS
    REDIS_URL: str = Field(..., min_length=10)
    REDIS_TTL_SHORT: int = 300
    REDIS_TTL_LONG: int = 3600

    # APP CONFIG
    ENVIRONMENT: str = "development"
    APP_HOST: str = "0.0.0.0"
    DEBUG: bool = False
    LOG_LEVEL: str = "DEBUG"
    LOG_FORMAT: str = "json"
    LOG_TO_CLOUDWATCH: bool = False
    CLOUDWATCH_LOG_GROUP: str = "/ecs/poultry-api"
    APP_PORT: int = 8000

    # CORS
    ALLOWED_ORIGINS: list[str] = Field(
        default_factory=lambda: [
            "http://localhost:5173",
            "http://localhost:8081",
            "http://localhost:3000",
        ]
    )

    # Notifications / communication
    EXPO_ACCESS_TOKEN: str = ""
    SMTP_SERVER: str = ""
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    SENDER_EMAIL: str = ""
    SENDER_NAME: str = "Poultry Farm Command Center"
    SNS_TOPIC_ARN_CRITICAL: str = ""
    SNS_TOPIC_ARN_WARNING: str = ""

    # Feature flags
    ENABLE_RLS: bool = True
    ENABLE_ANALYTICS: bool = True
    ENABLE_PUSH_NOTIFICATIONS: bool = True
    ENABLE_WHATSAPP_ALERTS: bool = False
    ENABLE_DAILY_BACKUP: bool = False
    BACKUP_S3_BUCKET: str = ""
    BACKUP_RETENTION_DAYS: int = 7

    # Rate limits
    RATE_LIMIT_ENABLED: bool = True
    RATE_LIMIT_REQUESTS_PER_MINUTE: int = 100
    RATE_LIMIT_REQUESTS_PER_HOUR: int = 5000

    @field_validator("ALLOWED_ORIGINS", mode="before")
    @classmethod
    def parse_allowed_origins(cls, value):
        if isinstance(value, str):
            return [origin.strip() for origin in value.split(",") if origin.strip()]
        return value


settings = Settings()

