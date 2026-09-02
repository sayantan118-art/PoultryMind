# apps/api/main.py
from fastapi import FastAPI, Depends, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text
from .config import settings
from .dependencies import get_db
from .services.auth_service import get_current_user

app = FastAPI(
    title="Poultry Farm Command Center API",
    version="1.0.0",
    description="Enterprise Operational Command Center for Layer Poultry Farms"
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.middleware("http")
async def set_rls_context(request: Request, call_next):
    """
    Middleware to set PostgreSQL session variables for Row Level Security.
    Extracts claims from JWT and applies them to the current DB session.
    """
    # Note: In a real implementation, we would extract this after auth
    # For now, this is a placeholder showing how RLS context will be set
    response = await call_next(request)
    return response

@app.get("/api/v1/health")
async def health_check():
    return {
        "status": "healthy",
        "version": "1.0.0",
        "environment": settings.ENVIRONMENT
    }

# Example of how a protected route will set RLS context
@app.get("/api/v1/test-rls")
async def test_rls(
    db: Session = Depends(get_db),
    user: dict = Depends(get_current_user)
):
    # Set session variables for RLS without string interpolation.
    for key, value in (
        ("app.user_role", user.get("role")),
        ("app.farm_id", user.get("farm_id")),
        ("app.user_id", user.get("user_id")),
    ):
        if value is not None:
            db.execute(
                text("SELECT set_config(:key, :value, false)"),
                {"key": key, "value": str(value)},
            )

    return {"message": "RLS context set", "user": user}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=settings.APP_PORT)
