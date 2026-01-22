from pydantic import BaseModel, EmailStr
from typing import Optional, List


class CreateAccountRequest(BaseModel):
    name: str
    email: EmailStr
    country: str = "US"

class CreateAccountResponse(BaseModel):
    id: str
    created: str

class ExternalAccountSummary(BaseModel):
    id: str
    bank_name: Optional[str] = None
    last4: str
    currency: str
    default_for_currency: bool


class AccountResponse(BaseModel):
    id: str
    email: Optional[str] = None
    business_name: Optional[str] = None
    charges_enabled: bool
    payouts_enabled: bool
    details_submitted: bool
    external_accounts: List[ExternalAccountSummary] = []
    created: int

    @classmethod
    def from_stripe_account(cls, account) -> "AccountResponse":
        external_accounts = []
        if account.external_accounts and account.external_accounts.data:
            for ea in account.external_accounts.data:
                external_accounts.append(
                    ExternalAccountSummary(
                        id=ea.id,
                        bank_name=getattr(ea, "bank_name", None),
                        last4=ea.last4,
                        currency=ea.currency,
                        default_for_currency=ea.default_for_currency or False,
                    )
                )

        return cls(
            id=account.id,
            email=account.email,
            business_name=account.business_profile.name if account.business_profile else None,
            charges_enabled=account.charges_enabled,
            payouts_enabled=account.payouts_enabled,
            details_submitted=account.details_submitted,
            external_accounts=external_accounts,
            created=account.created,
        )


class AccountListResponse(BaseModel):
    accounts: List[AccountResponse]
