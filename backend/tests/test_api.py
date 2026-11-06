"""End-to-end API tests using an in-memory fake MongoDB (mongomock).

Run:  pip install -r requirements-dev.txt && pytest
"""
import mongomock
import pymongo

# Swap the real MongoClient for the fake one BEFORE the app is imported.
pymongo.MongoClient = mongomock.MongoClient

from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402


def auth(token):
    return {"Authorization": f"Bearer {token}"}


def test_full_flow():
    with TestClient(app) as c:
        # --- register two users ---
        r = c.post("/auth/register", json={"name": "Alice", "email": "alice@x.com", "password": "secret1"})
        assert r.status_code == 201
        alice = r.json()
        assert alice["user"]["role"] == "user"
        r = c.post("/auth/register", json={"name": "Bob", "email": "bob@x.com", "password": "secret2"})
        bob = r.json()

        # duplicate email
        r = c.post("/auth/register", json={"name": "A2", "email": "ALICE@x.com", "password": "secret1"})
        assert r.status_code == 409

        # --- login ---
        assert c.post("/auth/login", json={
            "email": "alice@x.com",
            "password": "wrong",
            "latitude": 19.100531,
            "longitude": 72.916357,
        }).status_code == 401
        r = c.post("/auth/login", json={
            "email": "admin@example.com",
            "password": "Admin@123",
            "latitude": 19.100531,
            "longitude": 72.916357,
        })
        assert r.status_code == 200
        admin = r.json()
        assert admin["user"]["role"] == "admin"

        # --- no / bad token ---
        assert c.get("/auth/me").status_code == 401
        assert c.get("/auth/me", headers=auth("garbage")).status_code == 401
        assert c.get("/auth/me", headers=auth(alice["access_token"])).json()["email"] == "alice@x.com"

        # --- role checks ---
        assert c.get("/admin/users", headers=auth(alice["access_token"])).status_code == 403
        assert c.get("/messages/me", headers=auth(admin["access_token"])).status_code == 403
        assert c.get("/admin/users").status_code == 401

        # --- users send messages ---
        location = {"latitude": 19.100531, "longitude": 72.916357}
        missing_location = c.post(
            "/messages/me",
            json={"text": "Missing location"},
            headers=auth(alice["access_token"]),
        )
        assert missing_location.status_code == 422
        assert {error["loc"][-1] for error in missing_location.json()["detail"]} == {
            "latitude",
            "longitude",
        }
        r = c.post("/messages/me", json={"text": "  Hello admin  ", **location}, headers=auth(alice["access_token"]))
        assert r.status_code == 201 and r.json()["text"] == "Hello admin"
        c.post("/messages/me", json={"text": "Need help", **location}, headers=auth(alice["access_token"]))
        c.post("/messages/me", json={"text": "Hi from Bob", **location}, headers=auth(bob["access_token"]))
        assert c.post("/messages/me", json={"text": "   "}, headers=auth(alice["access_token"])).status_code == 422

        # --- admin sees all users with unread counts ---
        r = c.get("/admin/users", headers=auth(admin["access_token"]))
        users = {u["email"]: u for u in r.json()}
        assert set(users) == {"alice@x.com", "bob@x.com"}  # admin not listed
        assert users["alice@x.com"]["unread_count"] == 2
        assert users["bob@x.com"]["unread_count"] == 1

        # --- admin reads Alice's conversation (marks as read) and replies ---
        alice_id = alice["user"]["id"]
        r = c.get(f"/admin/users/{alice_id}/messages", headers=auth(admin["access_token"]))
        assert [m["text"] for m in r.json()] == ["Hello admin", "Need help"]
        assert all(m["out_of_office"] is False for m in r.json())
        r = c.post(f"/admin/users/{alice_id}/messages", json={"text": "How can I help?"},
                   headers=auth(admin["access_token"]))
        assert r.status_code == 201 and r.json()["sender_role"] == "admin"

        users = {u["email"]: u for u in c.get("/admin/users", headers=auth(admin["access_token"])).json()}
        assert users["alice@x.com"]["unread_count"] == 0
        assert users["bob@x.com"]["unread_count"] == 1

        # --- Alice sees the reply; Bob does not see Alice's messages ---
        r = c.get("/messages/me", headers=auth(alice["access_token"]))
        assert [m["sender_role"] for m in r.json()] == ["user", "user", "admin"]
        r = c.get("/messages/me", headers=auth(bob["access_token"]))
        assert [m["text"] for m in r.json()] == ["Hi from Bob"]

        # --- bad ids ---
        assert c.get("/admin/users/not-an-id/messages", headers=auth(admin["access_token"])).status_code == 404
