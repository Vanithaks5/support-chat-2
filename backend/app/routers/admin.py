"""Admin-only endpoints: see all users, read their messages, reply."""
from fastapi import APIRouter, Depends, HTTPException

from ..database import messages, users
from ..deps import require_admin
from ..schemas import MessageIn
from ..serializers import iso, message_out, to_object_id, utcnow

router = APIRouter(prefix="/admin", tags=["admin"], dependencies=[Depends(require_admin)])


def _get_user_or_404(user_id: str) -> dict:
    user = users.find_one({"_id": to_object_id(user_id), "role": "user"})
    if user is None:
        raise HTTPException(404, "User not found")
    return user


@router.get("/users")
def list_users():
    """All users, with their last message and unread count. Newest activity first."""
    result = []
    for u in users.find({"role": "user"}):
        last = messages.find_one({"user_id": u["_id"]}, sort=[("created_at", -1)])
        unread = messages.count_documents(
            {"user_id": u["_id"], "sender_role": "user", "read_by_admin": False}
        )
        result.append(
            {
                "id": str(u["_id"]),
                "name": u["name"],
                "email": u["email"],
                "last_message": last["text"] if last else None,
                "last_message_at": iso(last["created_at"]) if last else None,
                "unread_count": unread,
            }
        )
    result.sort(key=lambda r: r["last_message_at"] or "", reverse=True)
    return result


@router.get("/users/{user_id}/messages")
def user_conversation(user_id: str):
    user = _get_user_or_404(user_id)
    # Opening the conversation marks the user's messages as read.
    messages.update_many(
        {"user_id": user["_id"], "sender_role": "user", "read_by_admin": False},
        {"$set": {"read_by_admin": True}},
    )
    docs = messages.find({"user_id": user["_id"]}).sort("created_at", 1)
    return [message_out(d, include_internal=True) for d in docs]


@router.post("/users/{user_id}/messages", status_code=201)
def reply(user_id: str, body: MessageIn):
    user = _get_user_or_404(user_id)
    doc = {
        "user_id": user["_id"],
        "sender_role": "admin",
        "text": body.text,
        "created_at": utcnow(),
    }
    doc["_id"] = messages.insert_one(doc).inserted_id
    return message_out(doc)
