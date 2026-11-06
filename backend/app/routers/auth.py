"""Register, login and "who am I"."""
from fastapi import APIRouter, Depends, HTTPException
from pymongo.errors import DuplicateKeyError

from ..database import users
from ..deps import get_current_user
from ..geofence import is_out_of_office
from ..schemas import LoginIn, RegisterIn
from ..security import create_access_token, hash_password, verify_password
from ..serializers import user_out, utcnow

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", status_code=201)
def register(body: RegisterIn):
    """Public sign-up. Always creates a normal 'user' - never an admin."""
    out_of_office = is_out_of_office(body.latitude, body.longitude)
    doc = {
        "name": body.name,
        "email": body.email.lower(),
        "password_hash": hash_password(body.password),
        "role": "user",
        "created_at": utcnow(),
    }
    try:
        result = users.insert_one(doc)
    except DuplicateKeyError:
        raise HTTPException(409, "An account with this email already exists")
    doc["_id"] = result.inserted_id
    return {
        "access_token": create_access_token(
            str(doc["_id"]), doc["role"], out_of_office
        ),
        "token_type": "bearer",
        "user": user_out(doc),
    }


@router.post("/login")
def login(body: LoginIn):
    user = users.find_one({"email": body.email.lower()})
    if user is None or not verify_password(body.password, user["password_hash"]):
        raise HTTPException(401, "Incorrect email or password")
    out_of_office = is_out_of_office(body.latitude, body.longitude)
    return {
        "access_token": create_access_token(
            str(user["_id"]), user["role"], out_of_office
        ),
        "token_type": "bearer",
        "user": user_out(user),
    }


@router.get("/me")
def me(user: dict = Depends(get_current_user)):
    return user_out(user)
