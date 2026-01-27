package com.example.stripeapplication.data.models

import com.google.gson.annotations.SerializedName

data class Account(
    val id: String,
    @SerializedName("stripe_account_id")
    val stripeAccountId: String,
    @SerializedName("stripe_customer_id")
    val stripeCustomerId: String?,
    val email: String?,
    @SerializedName("display_name")
    val displayName: String?,
    val created: String,
    @SerializedName("is_customer")
    val isCustomer: Boolean,
    @SerializedName("is_recipient")
    val isRecipient: Boolean,
    @SerializedName("is_onboarding")
    val isOnboarding: Boolean? = false,
    @SerializedName("customer_capabilities")
    val customerCapabilities: Map<String, Any>? = null,
    @SerializedName("merchant_capabilities")
    val merchantCapabilities: Map<String, Any>? = null
)

data class AccountsResponse(
    val accounts: List<Account>
)

data class CreateAccountRequest(
    val name: String,
    val email: String,
    val country: String = "US"
)

data class CardDetails(
    val brand: String,
    val last4: String,
    @SerializedName("exp_month")
    val expMonth: Int,
    @SerializedName("exp_year")
    val expYear: Int
)

data class PaymentMethod(
    val id: String,
    val type: String,
    val card: CardDetails?,
    val created: Long
)

data class PaymentMethodsResponse(
    @SerializedName("payment_methods")
    val paymentMethods: List<PaymentMethod>
)

data class SetupIntentResponse(
    @SerializedName("client_secret")
    val clientSecret: String,
    @SerializedName("setup_intent_id")
    val setupIntentId: String,
    @SerializedName("customer_id")
    val customerId: String? = null
)

data class ExternalAccount(
    val id: String,
    val `object`: String,
    @SerializedName("bank_name")
    val bankName: String?,
    val last4: String,
    @SerializedName("routing_number")
    val routingNumber: String?,
    val currency: String,
    val country: String,
    @SerializedName("default_for_currency")
    val defaultForCurrency: Boolean,
    val status: String?
)

data class ExternalAccountsResponse(
    @SerializedName("external_accounts")
    val externalAccounts: List<ExternalAccount>
)

data class CreateExternalAccountRequest(
    val token: String
)

data class PayUserRequest(
    val amount: Int,
    val currency: String = "usd",
    @SerializedName("recipient_account_id")
    val recipientAccountId: String,
    @SerializedName("payment_method_id")
    val paymentMethodId: String
)

data class PayUserResponse(
    val id: String,
    val amount: Int,
    val currency: String,
    val status: String,
    val recipient: String,
    val transfer: String?,
    val created: Long
)

data class AccountLinkRequest(
    @SerializedName("refresh_url")
    val refreshUrl: String,
    @SerializedName("return_url")
    val returnUrl: String
)

data class AccountLinkResponse(
    val url: String,
    val created: String,
    @SerializedName("expires_at")
    val expiresAt: String
)

data class CreatePaymentIntentRequest(
    val amount: Int,
    val currency: String = "usd",
    @SerializedName("recipient_account_id")
    val recipientAccountId: String,
    @SerializedName("save_payment_method")
    val savePaymentMethod: Boolean
)

data class CreatePaymentIntentResponse(
    @SerializedName("client_secret")
    val clientSecret: String,
    @SerializedName("payment_intent_id")
    val paymentIntentId: String,
    val amount: Int,
    val currency: String,
    val recipient: String
)

data class UpgradeToRecipientResponse(
    val id: String,
    @SerializedName("stripe_account_id")
    val stripeAccountId: String,
    @SerializedName("is_merchant")
    val isMerchant: Boolean,
    @SerializedName("is_recipient")
    val isRecipient: Boolean,
    @SerializedName("merchant_capabilities")
    val merchantCapabilities: Map<String, Any>?,
    @SerializedName("recipient_capabilities")
    val recipientCapabilities: Map<String, Any>?
)

data class ErrorResponse(
    val detail: String?
)
