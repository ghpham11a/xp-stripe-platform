package com.example.stripedemo.data.models

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
