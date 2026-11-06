"""FastAPI entry point.  Run with:  uvicorn app.main:app --reload"""
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import ADMIN_EMAIL, ADMIN_NAME, ADMIN_PASSWORD
from .database import init_indexes, users
from .routers import admin, auth, messages
from .security import hash_password
from .serializers import utcnow

log = logging.getLogger("uvicorn.error")


def seed_admin() -> None:
    """Create the admin account on first start if it does not exist."""
    if users.find_one({"email": ADMIN_EMAIL}) is None:
        users.insert_one(
            {
                "name": ADMIN_NAME,
                "email": ADMIN_EMAIL,
                "password_hash": hash_password(ADMIN_PASSWORD),
                "role": "admin",
                "created_at": utcnow(),
            }
        )
        log.info("Created admin account: %s", ADMIN_EMAIL)


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_indexes()
    seed_admin()
    yield


app = FastAPI(title="Support Chat API", lifespan=lifespan)

# Auth uses the Authorization header (no cookies), so a wildcard origin is fine for local dev.
# For production, replace "*" with your real frontend URL.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(messages.router)
app.include_router(admin.router)


@app.get("/")
def health():
    return {"status": "ok"}
