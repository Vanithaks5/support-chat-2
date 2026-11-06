# Support Chat - Flutter Web + FastAPI + MongoDB

A small role-based messaging app.

The frontend is branded as **Instaresponse** for HDFC Life, using the supplied
HDFC Life logo with red and blue brand colors.

- **User**: registers / logs in, sends messages to the admin, sees the admin's replies.
- **Admin**: logs in, sees every user (with unread counts), opens any conversation and replies.
- **Auth**: JWT bearer tokens (HS256), passwords hashed with bcrypt.
- **Geofencing**: User browser location is checked at sign-in against the configured
  office point. Messages sent from outside the radius are marked **Out of office**
  for admins only.
- Latitude and longitude are requested on every login attempt and before every
  user message. Sign-in/message sending is stopped when the browser does not
  provide both coordinates.
- After updating the frontend, restart `flutter run -d chrome` (or perform a
  hard refresh) so the browser uses the new message request that includes both
  coordinates.
- **Roles are enforced on the server** - the Flutter UI only picks which screen to show.

```
support-chat/
  backend/    Python (FastAPI) API
  frontend/   Flutter web app
```

## Prerequisites

- Python 3.15
- MongoDB running locally on `mongodb://localhost:27017`
  (or a free MongoDB Atlas connection string)
- Flutter 3.41.9 with web enabled (`flutter doctor` should show Chrome)

## 1. Run the backend

```bash
cd backend
python -m venv .venv

# macOS / Linux
source .venv/bin/activate
# Windows (PowerShell)
#   .venv\Scripts\Activate.ps1

pip install -r requirements.txt

# optional: customise settings (JWT secret, Mongo URI, admin credentials)
cp .env.example .env

uvicorn app.main:app --reload --port 8000
```

- API docs (try the endpoints in your browser): http://localhost:8000/docs
- On first start an **admin account is created automatically**:

  | Email | Password |
  |---|---|
  | `admin@example.com` | `Admin@123` |

  Change these in `.env` (`ADMIN_EMAIL`, `ADMIN_PASSWORD`) *before the first start*.
  The admin is only created if that email does not exist yet.

## 2. Run the frontend

In a second terminal:

```bash
cd frontend

# one-time: generate the web platform files (keeps the existing lib/ code)
flutter create . --platforms=web

flutter pub get
flutter run -d chrome
```

If your backend is not at `http://localhost:8000`:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:9000
```

## Try it

1. Open the app, click **Sign up**, create a user (e.g. `alice@example.com`).
2. Send a message.
3. Open a second browser profile / incognito window, sign in as the admin.
4. The admin sees Alice with an unread badge, opens the chat and replies.
5. Alice's screen updates within a few seconds (the apps poll every 4s).

## API overview

| Method | Path | Who | Purpose |
|---|---|---|---|
| POST | `/auth/register` | public | Create a normal user, returns JWT |
| POST | `/auth/login` | public | Returns JWT + user |
| GET | `/auth/me` | any logged in | Current user |
| GET | `/messages/me` | user | My conversation |
| POST | `/messages/me` | user | Send message to admin |
| GET | `/admin/users` | admin | All users + last message + unread count |
| GET | `/admin/users/{id}/messages` | admin | A user's conversation (marks as read) |
| POST | `/admin/users/{id}/messages` | admin | Reply to that user |

Send the token as `Authorization: Bearer <token>`.

## Data model (MongoDB, database `support_chat`)

- `users`: `name`, `email` (unique), `password_hash`, `role` (`user` | `admin`), `created_at`
- `messages`: `user_id` (the conversation owner), `sender_role`, `text`, `created_at`, `read_by_admin`

Each user has exactly one conversation with the admin, keyed by `user_id`.

## Tests (backend)

```bash
cd backend
pip install -r requirements-dev.txt
pytest
```

The test uses an in-memory fake MongoDB, so no database is needed. It covers
registration, login, token checks, role enforcement (403s), messaging and replies.

## Before deploying anywhere real

- Set a long random `JWT_SECRET` (`python -c "import secrets; print(secrets.token_hex(32))"`).
- Change the default admin password.
- Restrict CORS `allow_origins` in `backend/app/main.py` to your frontend URL.
- Serve over HTTPS.
- Set `OFFICE_LATITUDE`, `OFFICE_LONGITUDE`, and `OFFICE_RADIUS_METERS` in `.env`
  to your office coordinates and allowed radius. Browsers require HTTPS (or
  localhost) to provide location.
- Consider WebSockets instead of polling if you need instant delivery.
