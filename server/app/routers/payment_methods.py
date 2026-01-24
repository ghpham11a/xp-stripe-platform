import os
from typing import Optional

from fastapi import APIRouter, HTTPException, Query
from services.stripe_service import StripeService
import stripe

from services.database import get_platform_account, update_platform_account
from schemas.payment_method import (
    SetupIntentResponse,
    PaymentMethodResponse,
    PaymentMethodListResponse,
)

router = APIRouter(prefix="/api/accounts/{account_id}/payment-methods", tags=["payment-methods"])


@router.post("/setup-intent", response_model=SetupIntentResponse)
async def create_setup_intent(
    account_id: str,
    customer_id: Optional[str] = Query(None, description="Existing Stripe Customer ID")
):
    """Create a SetupIntent to collect a payment method for a platform account."""
    stripe.api_key = os.getenv("STRIPE_SECRET_KEY")

    try:
        # Look up platform account
        platform_account = get_platform_account(account_id)
        if not platform_account:
            raise HTTPException(status_code=404, detail="Account not found")

        customer_id = ""
        customer_id = StripeService.get_customer_id_for_account_with_account_id(account_id=platform_account.stripe_account_id)

        if customer_id == "":
            raise HTTPException(status_code=400, detail="Account has no customer ID")

        setup_intent = stripe.SetupIntent.create(
            customer=customer_id,
            usage="off_session",
            payment_method_types=["card"],
            metadata={
                "platform_account_id": account_id,
                "stripe_account_id": platform_account.stripe_account_id,
            },
        )

        return SetupIntentResponse(
            client_secret=setup_intent.client_secret,
            setup_intent_id=setup_intent.id,
            customer_id=customer_id,
        )
    except HTTPException:
        raise
    except stripe.error.InvalidRequestError as e:
        raise HTTPException(status_code=404, detail="Customer not found")
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e.user_message or e))


@router.get("", response_model=PaymentMethodListResponse)
async def list_payment_methods(account_id: str):
    """List payment methods attached to a platform account."""
    stripe.api_key = os.getenv("STRIPE_SECRET_KEY")

    try:
        # Look up platform account
        platform_account = get_platform_account(account_id)
        if not platform_account:
            raise HTTPException(status_code=404, detail="Account not found")

        # Use the platform account's stripe_customer_id
        customer_id = StripeService.get_customer_id_for_account_with_account_id(account_id=platform_account.stripe_account_id)

        if not customer_id:
            return PaymentMethodListResponse(payment_methods=[])

        payment_methods = stripe.PaymentMethod.list(
            customer=customer_id,
            type="card",
        )

        return PaymentMethodListResponse(
            payment_methods=[
                PaymentMethodResponse.from_stripe_payment_method(pm)
                for pm in payment_methods
            ]
        )
    except HTTPException:
        raise
    except stripe.error.InvalidRequestError as e:
        raise HTTPException(status_code=404, detail="Customer not found")
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e.user_message or e))


@router.delete("/{payment_method_id}")
async def delete_payment_method(account_id: str, payment_method_id: str):
    """Detach a payment method from a platform account."""
    stripe.api_key = os.getenv("STRIPE_SECRET_KEY")

    try:
        # Look up platform account (just to verify it exists)
        platform_account = get_platform_account(account_id)
        if not platform_account:
            raise HTTPException(status_code=404, detail="Account not found")

        # Detach the payment method
        stripe.PaymentMethod.detach(payment_method_id)

        return {"status": "detached", "payment_method_id": payment_method_id}
    except HTTPException:
        raise
    except stripe.error.InvalidRequestError as e:
        raise HTTPException(status_code=404, detail="Payment method not found")
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e.user_message or e))
