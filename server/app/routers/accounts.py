import os

from fastapi import APIRouter, HTTPException, Request
import stripe
from pydantic import BaseModel

from schemas.account import CreateAccountRequest
from services.database import (
    create_platform_account,
    get_platform_account,
    list_platform_accounts,
    delete_platform_account,
)

router = APIRouter(prefix="/api/accounts", tags=["accounts"])


@router.post("")
async def create_account(request: CreateAccountRequest):

    """Create a new v2 customer account."""
    stripe.api_key = os.getenv("STRIPE_SECRET_KEY")

    try:

        stripe_client = stripe.StripeClient(
            os.getenv("STRIPE_SECRET_KEY"),
            stripe_version="2025-12-15.preview"
        )

        # Create Stripe v2 account
        account = stripe_client.v2.core.accounts.create({
            "contact_email": request.email,
            "display_name": request.name,
            "identity": {
                "country": "us",
            },
            "configuration": {
                "customer": {
                    "capabilities": {
                        "automatic_indirect_tax": {"requested": True}
                    }
                },
            },
            "defaults": {
                "currency": "usd",
                "locales": ["en-US"],
            },
            "include": [
                "configuration.customer",
                "identity",
                "requirements",
                "defaults"
            ],
        })

        stripe_account_id = account.get("id", "")

        _ = stripe_client.v2.core.accounts.update(
            stripe_account_id,
            {
                "metadata": {
                    "account_id": stripe_account_id,
                },
            }
        )

        # Create platform account in our mock DB
        platform_account = create_platform_account(
            email=request.email,
            stripe_account_id=stripe_account_id,
            stripe_customer_id="",
        )

        config = account.get("configuration", {})
        return {
            "id": platform_account.id,
            "stripe_account_id": stripe_account_id,
            "stripe_customer_id": "customer.id",
            "email": account.get("contact_email"),
            "display_name": account.get("display_name"),
            "created": account.get("created", ""),
            "is_customer": config.get("customer") is not None,
            "is_recipient": config.get("recipient") is not None,
        }

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e.user_message or e))


@router.get("")
async def list_accounts():
    """List all platform accounts with their Stripe account details."""
    try:
        stripe_client = stripe.StripeClient(os.getenv("STRIPE_SECRET_KEY"))

        # Get all platform accounts from our mock DB
        platform_accounts = list_platform_accounts()

        accounts = []
        for pa in platform_accounts:
            try:
                # Fetch Stripe account details
                stripe_account = stripe_client.v2.core.accounts.retrieve(
                    pa.stripe_account_id,
                    {"include": ["configuration.customer", "configuration.recipient"]}
                )
                applied_configurations = stripe_account.get("applied_configurations", [])

                accounts.append({
                    "id": pa.id,
                    "stripe_account_id": pa.stripe_account_id,
                    "stripe_customer_id": pa.stripe_customer_id,
                    "email": stripe_account.get("contact_email"),
                    "display_name": stripe_account.get("display_name"),
                    "created": stripe_account.get("created", ""),
                    "is_customer": "customer" in applied_configurations,
                    "is_merchant": "merchant" in applied_configurations,
                    "is_recipient": "recipient" in applied_configurations,
                })
            except stripe.error.StripeError:
                # If Stripe account doesn't exist, still include platform account
                accounts.append({
                    "id": pa.id,
                    "stripe_account_id": pa.stripe_account_id,
                    "stripe_customer_id": pa.stripe_customer_id,
                    "email": pa.email,
                    "display_name": None,
                    "created": "",
                    "is_customer": False,
                    "is_merchant": False,
                    "is_recipient": False,
                })

        return {"accounts": accounts}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/{account_id}")
async def get_account(account_id: str):
    """Get a specific account by platform ID."""
    try:
        # Look up platform account
        platform_account = get_platform_account(account_id)
        if not platform_account:
            raise HTTPException(status_code=404, detail="Account not found")

        stripe_client = stripe.StripeClient(os.getenv("STRIPE_SECRET_KEY"))

        # Fetch Stripe account details
        account = stripe_client.v2.core.accounts.retrieve(
            platform_account.stripe_account_id,
            {
                "include": [
                    "configuration.customer",
                    "configuration.merchant",
                    "configuration.recipient",
                    "identity",
                    "requirements",
                    "defaults"
                ],
            }
        )

        config = account.get("configuration", {})

        recipient_capabilities = (config.get("recipient") or {}).get("capabilities", {})
        stripe_balance = recipient_capabilities.get("stripe_balance", {})
        payouts = stripe_balance.get("payouts", {})
        stripe_transfers = stripe_balance.get("stripe_transfers", {})
        payouts_status = payouts.get("status", "restricted")
        stripe_transfers_status = stripe_transfers.get("status", "restricted")

        return {
            "id": platform_account.id,
            "stripe_account_id": platform_account.stripe_account_id,
            "stripe_customer_id": platform_account.stripe_customer_id,
            "email": account.get("contact_email"),
            "display_name": account.get("display_name"),
            "created": account.get("created", ""),
            "requirements": account.get("requirements"),
            "is_customer": config.get("customer") is not None,
            "is_recipient": config.get("recipient") is not None,
            "is_onboarding": payouts_status == "restricted" or stripe_transfers_status == "restricted",
            "customer_capabilities": (config.get("customer") or {}).get("capabilities", {}),
            "recipient_capabilities": (config.get("recipient") or {}).get("capabilities", {}),
        }
    except HTTPException:
        raise
    except stripe.error.InvalidRequestError as e:
        raise HTTPException(status_code=404, detail="Stripe account not found")
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e.user_message or e))


@router.delete("/{account_id}")
async def delete_account(account_id: str):
    """Delete a platform account and its associated Stripe account."""
    try:
        # Look up platform account
        platform_account = get_platform_account(account_id)
        if not platform_account:
            raise HTTPException(status_code=404, detail="Account not found")

        stripe_client = stripe.StripeClient(os.getenv("STRIPE_SECRET_KEY"))

        # Delete the Stripe account
        try:
            stripe_client.v2.core.accounts.delete(platform_account.stripe_account_id)
        except stripe.error.StripeError as e:
            print(f"Warning: Could not delete Stripe account: {e}")

        # Delete the Stripe customer if exists
        if platform_account.stripe_customer_id:
            try:
                stripe.Customer.delete(platform_account.stripe_customer_id)
            except stripe.error.StripeError as e:
                print(f"Warning: Could not delete Stripe customer: {e}")

        # Delete from our mock DB
        delete_platform_account(account_id)

        return {"status": "deleted", "account_id": account_id}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/{account_id}/upgrade-to-recipient")
async def upgrade_to_recipient(request: Request, account_id: str):
    """Upgrade a customer account to also be a recipient (able to accept payments)."""
    stripe.api_key = os.getenv("STRIPE_SECRET_KEY")

    try:
        # Look up platform account
        platform_account = get_platform_account(account_id)
        if not platform_account:
            raise HTTPException(status_code=404, detail="Account not found")

        # Use preview version for recipient.capabilities.bank_accounts
        stripe_client = stripe.StripeClient(
            os.getenv("STRIPE_SECRET_KEY"),
            stripe_version="2025-12-15.preview"
        )

        account = stripe_client.v2.core.accounts.update(
            platform_account.stripe_account_id,
            {
                "identity": {
                    "entity_type": "individual",
                },
                "configuration": {
                    "recipient": {
                        "applied": True,
                        "capabilities": {
                            "stripe_balance": {
                                "stripe_transfers": {"requested": True}
                            }
                        }
                    }
                },
                "defaults": {
                    "currency": "usd",
                    "responsibilities": {
                        "losses_collector": "application",
                        "fees_collector": "application",
                    },
                    "profile": {
                        "product_description": "Gig worker on your platform",
                    },
                },
                "dashboard": "none",
                "include": [
                    "configuration.customer",
                    "configuration.recipient",
                    "identity",
                    "requirements"
                ],
            }
        )

        config = account.get("configuration", {})
        return {
            "id": platform_account.id,
            "stripe_account_id": account.get("id", ""),
            "is_merchant": config.get("merchant") is not None,
            "is_recipient": config.get("recipient") is not None,
            "merchant_capabilities": (config.get("merchant") or {}).get("capabilities", {}),
            "recipient_capabilities": (config.get("recipient") or {}).get("capabilities", {}),
        }
    except HTTPException:
        raise
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e.user_message or e))


class AccountLinkRequest(BaseModel):
    refresh_url: str
    return_url: str


@router.post("/{id}/onboarding-link")
async def create_onboarding_link(id: str, request: AccountLinkRequest):
    """Create an account link for recipient onboarding."""
    try:
        # Look up platform account
        platform_account = get_platform_account(id)
        if not platform_account:
            raise HTTPException(status_code=404, detail="Account not found")

        stripe_client = stripe.StripeClient(
            os.getenv("STRIPE_SECRET_KEY"),
            stripe_version="2025-12-15.preview"
        )

        # Check if account has recipient configuration
        account = stripe_client.v2.core.accounts.retrieve(
            platform_account.stripe_account_id,
            {"include": ["configuration.recipient"]}
        )

        # Verify recipient is in applied_configurations
        applied_configs = account.get("applied_configurations", [])
        if "recipient" not in applied_configs:
            raise HTTPException(
                status_code=400,
                detail="Account must be a recipient to create an onboarding link"
            )

        # Now create the onboarding link - must match applied configurations exactly
        account_link = stripe_client.v2.core.account_links.create({
            "account": platform_account.stripe_account_id,
            "use_case": {
                "type": "account_onboarding",
                "account_onboarding": {
                    "configurations": applied_configs,
                    "return_url": request.return_url,
                    "refresh_url": request.refresh_url,
                },
            },
        })

        return {
            "url": account_link.get("url"),
            "created": account_link.get("created"),
            "expires_at": account_link.get("expires_at"),
        }
    except HTTPException:
        raise
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e.user_message or e))
