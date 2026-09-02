# apps/api/config.py
from pydantic_settings import BaseSettings
from typing import List
from pathlib import Path

class Settings(BaseSettings):
    # DATABASE
    DATABASE_URL: str = "postgresql://user:pass@localhost:5432/poultry_dev"
    DATABASE_POOL_SIZE: int = 10
    DATABASE_MAX_OVERFLOW: int = 20

    # AWS
    AWS_ACCESS_KEY_ID: str = "your_key"
    AWS_SECRET_ACCESS_KEY: str = "your_secret"
    AWS_REGION: str = "ap-south-1"

    # AWS COGNITO
    COGNITO_USER_POOL_ID: str = ""
    COGNITO_CLIENT_ID: str = ""
    COGNITO_REGION: str = "ap-south-1"

    # JWT
    JWT_SECRET_KEY: str = "your_secret_key_min_32_chars"
    JWT_ALGORITHM: str = "HS256"

    # REDIS
    REDIS_URL: str = "redis://localhost:6379/0"

    # APP CONFIG
    ENVIRONMENT: str = "development"
    LOG_LEVEL: str = "DEBUG"
    APP_PORT: int = 8000
    
    ALLOWED_ORIGINS: List[str] = ["http://localhost:5173"]

    class Config:
        # Look for .env file, but don't fail if it doesn't exist
        env_file = ".env"
        # Allow overriding via environment variables
        case_sensitive = True

# Create settings instance
settings = Settings()

