from pydantic import BaseModel
from typing import Optional, List


class SetupIntentResponse(BaseModel):
    client_secret: str
    setup_intent_id: str


class CardDetails(BaseModel):
    brand: str
    last4: str
    exp_month: int
    exp_year: int


class PaymentMethodResponse(BaseModel):
    id: str
    type: str
    card: Optional[CardDetails] = None
    created: int

    @classmethod
    def from_stripe_payment_method(cls, pm) -> "PaymentMethodResponse":
        card = None
        if pm.type == "card" and pm.card:
            card = CardDetails(
                brand=pm.card.brand,
                last4=pm.card.last4,
                exp_month=pm.card.exp_month,
                exp_year=pm.card.exp_year,
            )

        return cls(
            id=pm.id,
            type=pm.type,
            card=card,
            created=pm.created,
        )


class PaymentMethodListResponse(BaseModel):
    payment_methods: List[PaymentMethodResponse]
