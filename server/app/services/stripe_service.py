import os
import time
import stripe
from typing import Optional

class StripeService:
    """Wrapper for Stripe API operations."""

    # --- Connected Accounts ---

    @staticmethod
    def create_connected_account(email: str, business_name: str, country: str = "US") -> stripe.Account:
        """Create a Custom connected account with minimal required fields for test mode."""

        stripe.api_key = os.getenv("STRIPE_SECRET_KEY")

        return stripe.Account.create(
            type="custom",
            country=country,
            email=email,
            capabilities={
                "card_payments": {"requested": True},
                "transfers": {"requested": True},
            },
            business_type="individual",
            business_profile={
                "name": business_name,
                "mcc": "5734",  # Computer Software Stores
                "url": "https://example.com",
            },
            individual={
                "first_name": "Test",
                "last_name": "User",
                "email": email,
                "dob": {"day": 1, "month": 1, "year": 1990},
                "address": {
                    "line1": "123 Test St",
                    "city": "San Francisco",
                    "state": "CA",
                    "postal_code": "94111",
                    "country": "US",
                },
                "ssn_last_4": "0000",  # Test mode only
            },
            tos_acceptance={
                "date": int(time.time()),
                "ip": "127.0.0.1",
            },
        )

    @staticmethod
    def list_connected_accounts(limit: int = 100) -> list:
        """List all connected accounts."""
        stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
        accounts = stripe.Account.list(limit=limit)
        return accounts.data

    @staticmethod
    def get_account(account_id: str) -> stripe.Account:
        """Get a specific connected account."""
        stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
        return stripe.Account.retrieve(account_id)

    @staticmethod
    def delete_account(account_id: str) -> stripe.Account:
        """Delete a connected account."""
        stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
        return stripe.Account.delete(account_id)

    # --- Payment Methods (SetupIntents) ---

    @staticmethod
    def create_setup_intent(account_id: str) -> stripe.SetupIntent:
        """Create a SetupIntent for collecting a payment method at the platform level."""
        stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
        return stripe.SetupIntent.create(
            usage="off_session",
            payment_method_types=["card"],
            metadata={"account_id": account_id},
        )

    @staticmethod
    def list_payment_methods(account_id: str, customer_id: Optional[str] = None) -> list:
        """List payment methods for an account (stored at platform level)."""
        stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
        # List SetupIntents at platform level, filter by account_id in metadata
        setup_intents = stripe.SetupIntent.list(limit=100)
        # Filter to only succeeded ones for this account and extract payment methods
        payment_methods = []
        for si in setup_intents.data:
            if (si.status == "succeeded" and
                si.payment_method and
                si.metadata.get("account_id") == account_id):
                try:
                    pm = stripe.PaymentMethod.retrieve(si.payment_method)
                    payment_methods.append(pm)
                except stripe.error.StripeError:
                    pass
        return payment_methods

    @staticmethod
    def detach_payment_method(account_id: str, payment_method_id: str) -> stripe.PaymentMethod:
        """Detach a payment method (stored at platform level)."""
        stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
        return stripe.PaymentMethod.detach(payment_method_id)

    # --- External Accounts (Bank Accounts) ---

    @staticmethod
    def create_external_account(account_id: str, token: str) -> stripe.BankAccount:
        """Add an external bank account to a connected account using a token."""
        stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
        return stripe.Account.create_external_account(
            account_id,
            external_account=token,
        )

    @staticmethod
    def list_external_accounts(account_id: str) -> list:
        """List external accounts (bank accounts) for a connected account."""
        stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
        account = stripe.Account.retrieve(account_id)
        if account.external_accounts:
            return account.external_accounts.data
        return []

    @staticmethod
    def delete_external_account(account_id: str, external_account_id: str):
        """Delete an external account from a connected account."""
        stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
        return stripe.Account.delete_external_account(
            account_id,
            external_account_id,
        )

    @staticmethod
    def set_default_external_account(account_id: str, external_account_id: str) -> stripe.BankAccount:
        """Set an external account as the default for payouts."""
        stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
        return stripe.Account.modify_external_account(
            account_id,
            external_account_id,
            default_for_currency=True,
        )
