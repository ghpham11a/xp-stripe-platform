import os

from fastapi import APIRouter, HTTPException
from services.stripe_service import StripeService
import stripe
from pydantic import BaseModel

from services.database import (
    get_platform_account,
)

router = APIRouter(prefix="/api/transactions", tags=["transactions"])


class PayUserRequest(BaseModel):
    amount: int  # Amount in cents
    currency: str = "usd"
    recipient_account_id: str  # The recipient's platform account ID
    payment_method_id: str  # The sender's payment method to charge


@router.post("/{account_id}/pay-user")
async def pay_user(account_id: str, request: PayUserRequest):
    """
    Pay another user using destination charges.
    Charges the sender's payment method and transfers funds to the recipient.
    """
    stripe.api_key = os.getenv("STRIPE_SECRET_KEY")

    try:
        # Look up sender platform account
        sender_account = get_platform_account(account_id)
        if not sender_account:
            raise HTTPException(status_code=404, detail="Sender account not found")

        # Look up recipient platform account
        recipient_account = get_platform_account(request.recipient_account_id)
        if not recipient_account:
            raise HTTPException(status_code=404, detail="Recipient account not found")

        # Use the sender's stripe_customer_id
        customer_id = StripeService.get_customer_id_for_account_with_account_id(sender_account.stripe_account_id)

        if not customer_id:
            raise HTTPException(status_code=400, detail="Sender has no customer ID")

        # Check if the payment method is already attached to this customer
        pm = stripe.PaymentMethod.retrieve(request.payment_method_id)
        if pm.customer != customer_id:
            # Attach the payment method to the customer
            stripe.PaymentMethod.attach(
                request.payment_method_id,
                customer=customer_id,
            )

        # Create a PaymentIntent with destination charge
        # Use the recipient's stripe_account_id for the transfer
        payment_intent = stripe.PaymentIntent.create(
            amount=request.amount,
            currency=request.currency,
            customer=customer_id,
            payment_method=request.payment_method_id,
            confirm=True,
            off_session=True,
            transfer_data={
                "destination": recipient_account.stripe_account_id,
            },
            metadata={
                "sender_platform_id": account_id,
                "recipient_platform_id": request.recipient_account_id,
                "sender_stripe_account": sender_account.stripe_account_id,
                "recipient_stripe_account": recipient_account.stripe_account_id,
            },
        )

        return {
            "id": payment_intent.id,
            "amount": payment_intent.amount,
            "currency": payment_intent.currency,
            "status": payment_intent.status,
            "recipient": request.recipient_account_id,
            "transfer": payment_intent.get("transfer_data", {}).get("destination"),
            "created": payment_intent.created,
        }
    except HTTPException:
        raise
    except stripe.error.CardError as e:
        raise HTTPException(status_code=400, detail=str(e.user_message or "Card was declined"))
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e.user_message or e))
