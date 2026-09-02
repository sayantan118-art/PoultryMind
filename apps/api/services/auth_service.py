# apps/api/services/auth_service.py
from jose import jwt, JWTError
from fastapi import HTTPException, status, Depends
from fastapi.security import OAuth2PasswordBearer
from ..config import settings
from typing import Optional
import time

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/v1/auth/owner-login")

class AuthService:
    @staticmethod
    def verify_token(token: str) -> dict:
        try:
            # In production, this would verify against Cognito's JWKS
            # For now, we'll use a local secret for development/mocking
            payload = jwt.decode(
                token, 
                settings.JWT_SECRET_KEY, 
                algorithms=[settings.JWT_ALGORITHM]
            )
            
            # Check expiration
            if payload.get("exp") < time.time():
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Token expired",
                    headers={"WWW-Authenticate": "Bearer"},
                )
                
            return payload
        except JWTError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )

def get_current_user(token: str = Depends(oauth2_scheme)) -> dict:
    return AuthService.verify_token(token)

def require_role(role: str):
    def role_checker(user: dict = Depends(get_current_user)):
        if user.get("role") != role:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Role {role} required"
            )
        return user
    return role_checker
