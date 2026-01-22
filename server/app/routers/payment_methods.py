from fastapi import APIRouter, HTTPException
import stripe

from services.stripe_service import StripeService
from schemas.payment_method import (
    SetupIntentResponse,
    PaymentMethodResponse,
    PaymentMethodListResponse,
)

router = APIRouter(prefix="/api/accounts/{account_id}/payment-methods", tags=["payment-methods"])


@router.post("/setup-intent", response_model=SetupIntentResponse)
async def create_setup_intent(account_id: str):
    """Create a SetupIntent to collect a payment method for a connected account."""
    try:
        setup_intent = StripeService.create_setup_intent(account_id)
        return SetupIntentResponse(
            client_secret=setup_intent.client_secret,
            setup_intent_id=setup_intent.id,
        )
    except stripe.error.InvalidRequestError as e:
        print(e)
        raise HTTPException(status_code=404, detail="Account not found")
    except stripe.error.StripeError as e:
        print(e)
        raise HTTPException(status_code=400, detail=str(e.user_message or e))


@router.get("", response_model=PaymentMethodListResponse)
async def list_payment_methods(account_id: str):
    """List payment methods attached to a connected account."""
    try:
        payment_methods = StripeService.list_payment_methods(account_id)
        return PaymentMethodListResponse(
            payment_methods=[
                PaymentMethodResponse.from_stripe_payment_method(pm)
                for pm in payment_methods
            ]
        )
    except stripe.error.InvalidRequestError as e:
        raise HTTPException(status_code=404, detail="Account not found")
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e.user_message or e))


@router.delete("/{payment_method_id}")
async def delete_payment_method(account_id: str, payment_method_id: str):
    """Detach a payment method from a connected account."""
    try:
        StripeService.detach_payment_method(account_id, payment_method_id)
        return {"status": "detached", "payment_method_id": payment_method_id}
    except stripe.error.InvalidRequestError as e:
        raise HTTPException(status_code=404, detail="Payment method not found")
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e.user_message or e))
