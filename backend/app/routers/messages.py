"""Endpoints for a normal user: talk to the admin."""
from fastapi import APIRouter, Depends

from ..database import messages
from ..deps import require_user
from ..geofence import is_out_of_office
from ..schemas import MessageIn, UserMessageIn
from ..serializers import message_out, utcnow

router = APIRouter(prefix="/messages", tags=["user messages"])


@router.get("/me")
def my_messages(user: dict = Depends(require_user)):
    docs = messages.find({"user_id": user["_id"]}).sort("created_at", 1)
    return [message_out(d) for d in docs]


@router.post("/me", status_code=201)
def send_message(body: UserMessageIn, user: dict = Depends(require_user)):
    doc = {
        "user_id": user["_id"],
        "sender_role": "user",
        "text": body.text,
        "created_at": utcnow(),
        "read_by_admin": False,
        "out_of_office": is_out_of_office(body.latitude, body.longitude),
    }
    doc["_id"] = messages.insert_one(doc).inserted_id
    return message_out(doc)
