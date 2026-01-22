import os
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Request
import stripe
from pydantic import BaseModel

from schemas.account import CreateAccountRequest

router = APIRouter(prefix="/api/accounts", tags=["accounts"])

@router.post("")
async def create_account(request: CreateAccountRequest):
    """Create a new v2 customer account."""
    stripe.api_key = os.getenv("STRIPE_SECRET_KEY")

    try:
        stripe_client = stripe.StripeClient(os.getenv("STRIPE_SECRET_KEY"))

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
                # "configuration.merchant",
                # "configuration.recipient",
                "identity",
                "requirements",
            ],
        })

        config = account.get("configuration", {})
        return {
            "id": account.get("id", ""),
            "email": account.get("contact_email"),
            "display_name": account.get("display_name"),
            "created": account.get("created", ""),
            "is_customer": config.get("customer") is not None,
            "is_recipient": config.get("recipient") is not None,
        }

    except stripe.error.StripeError as e:
        print(e)
        raise HTTPException(status_code=400, detail=str(e.user_message or e))

@router.get("")
async def list_accounts():
    """List all v2 customer accounts."""
    try:
        stripe_client = stripe.StripeClient(os.getenv("STRIPE_SECRET_KEY"))

        # Use v2 API to list accounts
        accounts_response = stripe_client.v2.core.accounts.list({
            "limit": 20,
            "applied_configurations": [
                "customer",
                # "merchant",
            ],
        })

        accounts = []
        for account in accounts_response.data:
            applied_configurations = account.get("applied_configurations", [])
            accounts.append({
                "id": account.get("id", ""),
                "email": account.get("contact_email"),
                "display_name": account.get("display_name"),
                "created": account.get("created", ""),
                "is_customer": "customer" in applied_configurations,
                "is_merchant": "merchant" in applied_configurations,
                "is_recipient": "recipient" in applied_configurations,
            })

        return {"accounts": accounts}
    except stripe.error.StripeError as e:
        print(e)
        raise HTTPException(status_code=400, detail=str(e.user_message or e))


@router.get("/{account_id}")
async def get_account(account_id: str):
    """Get a specific v2 account."""
    try:
        stripe_client = stripe.StripeClient(os.getenv("STRIPE_SECRET_KEY"))

        account = stripe_client.v2.core.accounts.retrieve(
            account_id,
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
            "id": account.get("id", ""),
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
    except stripe.error.InvalidRequestError as e:
        print(e)
        raise HTTPException(status_code=404, detail="Account not found")
    except stripe.error.StripeError as e:
        print(e)
        raise HTTPException(status_code=400, detail=str(e.user_message or e))


@router.delete("/{account_id}")
async def delete_account(account_id: str):
    """Delete a v2 account."""
    try:
        stripe_client = stripe.StripeClient(os.getenv("STRIPE_SECRET_KEY"))
        stripe_client.v2.core.accounts.delete(account_id)
        return {"status": "deleted", "account_id": account_id}
    except stripe.error.InvalidRequestError as e:
        raise HTTPException(status_code=404, detail="Account not found")
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e.user_message or e))


@router.post("/{account_id}/upgrade-to-recipient")
async def upgrade_to_recipient(request: Request, account_id: str):

    """Upgrade a customer account to also be a recipient (able to accept payments)."""
    stripe.api_key = os.getenv("STRIPE_SECRET_KEY")

    try:
        # Use preview version for recipient.capabilities.bank_accounts
        stripe_client = stripe.StripeClient(
            os.getenv("STRIPE_SECRET_KEY"),
            stripe_version="2025-12-15.preview"
        )

        account = stripe_client.v2.core.accounts.update(
            account_id,
            {
                "identity": {
                    "entity_type": "individual",
                },
                "configuration": {
                    # "merchant": {
                    #     "applied": False
                    # },
                    "recipient": {
                        "applied": True,
                        "capabilities": {
                            "stripe_balance": {
                                "stripe_transfers": {"requested": True}
                            }
                        }
                        # "capabilities": {
                        #     "bank_accounts": {
                        #         "local": {"requested": True},
                        #         "wire": {"requested": True},
                        #     }
                        # },
                    }
                },
                "defaults": {
                    "currency": "usd",
                    "responsibilities": {
                        "losses_collector": "application",
                        "fees_collector": "application",
                    },
                    # "responsibilities": {
                    #     "losses_collector": "stripe",
                    #     "fees_collector": "stripe",
                    # },
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
            "id": account.get("id", ""),
            "is_merchant": config.get("merchant") is not None,
            "is_recipient": config.get("recipient") is not None,
            "merchant_capabilities": (config.get("merchant") or {}).get("capabilities", {}),
            "recipient_capabilities": (config.get("recipient") or {}).get("capabilities", {}),
        }
    except stripe.error.StripeError as e:
        print(e)
        raise HTTPException(status_code=400, detail=str(e.user_message or e))


class AccountLinkRequest(BaseModel):
    refresh_url: str
    return_url: str


@router.post("/{account_id}/onboarding-link")
async def create_onboarding_link(account_id: str, request: AccountLinkRequest):
    """Create an account link for recipient onboarding."""
    try:
        stripe_client = stripe.StripeClient(
            os.getenv("STRIPE_SECRET_KEY"),
            stripe_version="2025-12-15.preview"
        )

        # First, check if account has recipient configuration - if not, add it
        account = stripe_client.v2.core.accounts.retrieve(
            account_id,
            {"include": ["configuration.recipient"]}
        )

        # Check if recipient is in applied_configurations
        applied_configs = account.get("applied_configurations", [])
        if "recipient" not in applied_configs:
            # Add recipient configuration to the account first
            print("Recipient not in applied configs, applying now...")
            updated = stripe_client.v2.core.accounts.update(
                account_id,
                {
                    "identity": {
                        "entity_type": "individual"
                    },
                    "configuration": {
                        "recipient": {
                            "applied": True,
                        },
                    },
                    "defaults": {
                        "currency": "usd",
                        "responsibilities": {
                            "losses_collector": "platform",
                            "fees_collector": "platform",
                        },
                    },
                    "dashboard": "none",
                }
            )

        # Re-fetch to get current applied_configurations
        account = stripe_client.v2.core.accounts.retrieve(
            account_id,
            {"include": ["configuration.recipient"]}
        )
        applied_configs = account.get("applied_configurations", [])

        # Now create the onboarding link - must match applied configurations exactly
        account_link = stripe_client.v2.core.account_links.create({
            "account": account_id,
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
    except stripe.error.StripeError as e:
        print(e)
        raise HTTPException(status_code=400, detail=str(e.user_message or e))


class SendMoneyRequest(BaseModel):
    amount: int  # Amount in cents
    currency: str = "usd"
    destination_account_id: str  # The merchant account to send money to


@router.post("/{account_id}/send-money")
async def send_money(account_id: str, request: SendMoneyRequest):
    """Send money from platform to a connected merchant account."""
    stripe.api_key = os.getenv("STRIPE_SECRET_KEY")

    try:
        # Create a transfer to the destination connected account
        transfer = stripe.Transfer.create(
            amount=request.amount,
            currency=request.currency,
            destination=request.destination_account_id,
            metadata={
                "source_account": account_id,
            }
        )

        return {
            "id": transfer.id,
            "amount": transfer.amount,
            "currency": transfer.currency,
            "destination": transfer.destination,
            "created": transfer.created,
        }
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e.user_message or e))
