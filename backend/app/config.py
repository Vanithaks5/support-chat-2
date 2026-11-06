"""Settings, read from environment variables (or a .env file)."""
import os

from dotenv import load_dotenv

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI", "mongodb+srv://jayasrimanth:LalVuW4c8JTOS88L@cluster0.ahgw7uq.mongodb.net/")
DB_NAME = os.getenv("DB_NAME", "support_chat")

JWT_SECRET = os.getenv("JWT_SECRET", "dev-only-secret-change-me-before-deploying-1234567890")
JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))

# Override these with the office coordinates in .env.
OFFICE_LATITUDE = float(os.getenv("OFFICE_LATITUDE", "19.100531"))
OFFICE_LONGITUDE = float(os.getenv("OFFICE_LONGITUDE", "72.916357"))
OFFICE_RADIUS_METERS = float(os.getenv("OFFICE_RADIUS_METERS", "200"))

ADMIN_NAME = os.getenv("ADMIN_NAME", "Admin")
ADMIN_EMAIL = os.getenv("ADMIN_EMAIL", "admin@example.com").lower()
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "Admin@123")
