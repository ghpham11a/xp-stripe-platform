from pydantic import BaseModel
from typing import Optional, List


class CreateExternalAccountRequest(BaseModel):
    token: str  # Bank account token from Stripe.js


class ExternalAccountResponse(BaseModel):
    id: str
    object: str
    bank_name: Optional[str] = None
    last4: str
    routing_number: Optional[str] = None
    currency: str
    country: str
    default_for_currency: bool
    status: Optional[str] = None

    @classmethod
    def from_stripe_external_account(cls, ea) -> "ExternalAccountResponse":
        return cls(
            id=ea.id,
            object=ea.object,
            bank_name=getattr(ea, "bank_name", None),
            last4=ea.last4,
            routing_number=getattr(ea, "routing_number", None),
            currency=ea.currency,
            country=ea.country,
            default_for_currency=ea.default_for_currency or False,
            status=getattr(ea, "status", None),
        )


class ExternalAccountListResponse(BaseModel):
    external_accounts: List[ExternalAccountResponse]
