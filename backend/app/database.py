"""MongoDB connection and collections."""
from pymongo import ASCENDING, MongoClient

from .config import DB_NAME, MONGO_URI

client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
db = client[DB_NAME]

users = db["users"]
messages = db["messages"]


def init_indexes() -> None:
    users.create_index("email", unique=True)
    messages.create_index([("user_id", ASCENDING), ("created_at", ASCENDING)])
