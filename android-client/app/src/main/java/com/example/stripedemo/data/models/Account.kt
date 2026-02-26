package com.example.stripedemo.data.models

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class Account(
    val id: String,
    @Json(name = "stripe_account_id")
    val stripeAccountId: String,
    @Json(name = "stripe_customer_id")
    val stripeCustomerId: String?,
    val email: String?,
    @Json(name = "display_name")
    val displayName: String?,
    val created: String,
    @Json(name = "is_customer")
    val isCustomer: Boolean,
    @Json(name = "is_recipient")
    val isRecipient: Boolean,
    @Json(name = "is_onboarding")
    val isOnboarding: Boolean? = false,
    @Json(name = "customer_capabilities")
    val customerCapabilities: Map<String, Any?>? = null,
    @Json(name = "merchant_capabilities")
    val merchantCapabilities: Map<String, Any?>? = null
)

@JsonClass(generateAdapter = true)
data class AccountsResponse(
    val accounts: List<Account>
)

@JsonClass(generateAdapter = true)
data class CreateAccountRequest(
    val name: String,
    val email: String,
    val country: String = "US"
)
