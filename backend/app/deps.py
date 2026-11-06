"""Authentication and role-based access dependencies."""
import jwt
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from .database import users
from .security import decode_token
from .serializers import to_object_id

bearer_scheme = HTTPBearer(auto_error=False)

_UNAUTH = {"WWW-Authenticate": "Bearer"}


def get_current_user(
    creds: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> dict:
    if creds is None:
        raise HTTPException(401, "Not authenticated", headers=_UNAUTH)
    try:
        payload = decode_token(creds.credentials)
    except jwt.PyJWTError:
        raise HTTPException(401, "Invalid or expired token", headers=_UNAUTH)

    try:
        user = users.find_one({"_id": to_object_id(payload.get("sub", ""))})
    except HTTPException:
        user = None
    if user is None:
        raise HTTPException(401, "User no longer exists", headers=_UNAUTH)
    user["_out_of_office"] = bool(payload.get("out_of_office", True))
    return user


def require_role(*roles: str):
    """Dependency factory: only allow users whose (database) role is listed."""

    def checker(user: dict = Depends(get_current_user)) -> dict:
        if user["role"] not in roles:
            raise HTTPException(403, "You do not have permission to do this")
        return user

    return checker


require_user = require_role("user")
require_admin = require_role("admin")
