"""Helpers that turn MongoDB documents into JSON-friendly dicts."""
from datetime import datetime, timezone

from bson import ObjectId
from bson.errors import InvalidId
from fastapi import HTTPException


def to_object_id(value: str) -> ObjectId:
    try:
        return ObjectId(value)
    except (InvalidId, TypeError):
        raise HTTPException(status_code=404, detail="Not found")


def utcnow() -> datetime:
    """Naive UTC datetime (what MongoDB stores)."""
    return datetime.now(timezone.utc).replace(tzinfo=None)


def iso(dt: datetime | None) -> str | None:
    # MongoDB returns naive UTC datetimes; mark them as UTC explicitly.
    return None if dt is None else dt.replace(tzinfo=None).isoformat() + "Z"


def user_out(doc: dict) -> dict:
    return {
        "id": str(doc["_id"]),
        "name": doc["name"],
        "email": doc["email"],
        "role": doc["role"],
    }


def message_out(doc: dict, include_internal: bool = False) -> dict:
    result = {
        "id": str(doc["_id"]),
        "user_id": str(doc["user_id"]),
        "sender_role": doc["sender_role"],
        "text": doc["text"],
        "created_at": iso(doc["created_at"]),
    }
    if include_internal:
        result["out_of_office"] = bool(doc.get("out_of_office", False))
    return result
