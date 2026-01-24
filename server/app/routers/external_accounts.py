from fastapi import APIRouter, HTTPException
from services.database import get_platform_account
import stripe
import os

from services.stripe_service import StripeService
from schemas.external_account import (
    CreateExternalAccountRequest,
    ExternalAccountResponse,
    ExternalAccountListResponse,
)

router = APIRouter(prefix="/api/accounts/{account_id}/external-accounts", tags=["external-accounts"])


@router.post("", response_model=ExternalAccountResponse)
async def create_external_account(account_id: str, request: CreateExternalAccountRequest):
    """Add a bank account to a connected account using a token from Stripe.js."""
    try:
        external_account = StripeService.create_external_account(account_id, request.token)
        return ExternalAccountResponse.from_stripe_external_account(external_account)
    except stripe.error.InvalidRequestError as e:
        raise HTTPException(status_code=400, detail=str(e.user_message or e))
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e.user_message or e))


@router.get("", response_model=ExternalAccountListResponse)
async def list_external_accounts(account_id: str):
    """List external accounts (bank accounts) for a connected account."""
    try:
        platform_account = get_platform_account(account_id)
        stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
        external_accounts = StripeService.list_external_accounts(platform_account.stripe_account_id)
        return ExternalAccountListResponse(
            external_accounts=[
                ExternalAccountResponse.from_stripe_external_account(ea)
                for ea in external_accounts
            ]
        )
    except stripe.error.InvalidRequestError as e:
        raise HTTPException(status_code=404, detail="Account not found")
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e.user_message or e))


@router.delete("/{external_account_id}")
async def delete_external_account(account_id: str, external_account_id: str):
    """Remove an external account from a connected account."""
    try:
        StripeService.delete_external_account(account_id, external_account_id)
        return {"status": "deleted", "external_account_id": external_account_id}
    except stripe.error.InvalidRequestError as e:
        raise HTTPException(status_code=404, detail="External account not found")
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e.user_message or e))


@router.patch("/{external_account_id}/default", response_model=ExternalAccountResponse)
async def set_default_external_account(account_id: str, external_account_id: str):
    """Set an external account as the default for payouts."""
    try:
        external_account = StripeService.set_default_external_account(account_id, external_account_id)
        return ExternalAccountResponse.from_stripe_external_account(external_account)
    except stripe.error.InvalidRequestError as e:
        raise HTTPException(status_code=404, detail="External account not found")
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e.user_message or e))
