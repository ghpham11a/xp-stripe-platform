import json
import os
import uuid
from typing import Optional, List
from schemas.account import PlatformAccount

DB_FILE = os.path.join(os.path.dirname(__file__), "..", "data", "accounts.json")


def _ensure_db_exists():
    """Ensure the database file and directory exist."""
    db_dir = os.path.dirname(DB_FILE)
    if not os.path.exists(db_dir):
        os.makedirs(db_dir)
    if not os.path.exists(DB_FILE):
        with open(DB_FILE, "w") as f:
            json.dump({"accounts": []}, f)


def _read_db() -> dict:
    """Read the database file."""
    _ensure_db_exists()
    with open(DB_FILE, "r") as f:
        return json.load(f)


def _write_db(data: dict):
    """Write to the database file."""
    _ensure_db_exists()
    with open(DB_FILE, "w") as f:
        json.dump(data, f, indent=2)


def generate_id() -> str:
    """Generate a unique platform account ID."""
    return f"plat_{uuid.uuid4().hex[:16]}"


def create_platform_account(
    email: str,
    stripe_account_id: str,
    stripe_customer_id: str = ""
) -> PlatformAccount:
    """Create and store a new platform account."""
    db = _read_db()

    account = PlatformAccount(
        id=generate_id(),
        email=email,
        stripe_account_id=stripe_account_id,
        stripe_customer_id=stripe_customer_id,
    )

    db["accounts"].append(account.model_dump())
    _write_db(db)

    return account


def get_platform_account(account_id: str) -> Optional[PlatformAccount]:
    """Get a platform account by its ID."""
    db = _read_db()

    for account in db["accounts"]:
        if account["id"] == account_id:
            return PlatformAccount(**account)

    return None


def get_platform_account_by_stripe_id(stripe_account_id: str) -> Optional[PlatformAccount]:
    """Get a platform account by its Stripe account ID."""
    db = _read_db()

    for account in db["accounts"]:
        if account["stripe_account_id"] == stripe_account_id:
            return PlatformAccount(**account)

    return None


def list_platform_accounts() -> List[PlatformAccount]:
    """List all platform accounts."""
    db = _read_db()
    return [PlatformAccount(**account) for account in db["accounts"]]


def update_platform_account(account_id: str, **updates) -> Optional[PlatformAccount]:
    """Update a platform account."""
    db = _read_db()

    for i, account in enumerate(db["accounts"]):
        if account["id"] == account_id:
            db["accounts"][i].update(updates)
            _write_db(db)
            return PlatformAccount(**db["accounts"][i])

    return None


def delete_platform_account(account_id: str) -> bool:
    """Delete a platform account."""
    db = _read_db()

    for i, account in enumerate(db["accounts"]):
        if account["id"] == account_id:
            db["accounts"].pop(i)
            _write_db(db)
            return True

    return False
