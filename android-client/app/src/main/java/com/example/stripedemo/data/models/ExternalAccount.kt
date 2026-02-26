package com.example.stripedemo.data.models

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class ExternalAccount(
    val id: String,
    @Json(name = "object")
    val objectType: String,
    @Json(name = "bank_name")
    val bankName: String?,
    val last4: String,
    @Json(name = "routing_number")
    val routingNumber: String?,
    val currency: String,
    val country: String,
    @Json(name = "default_for_currency")
    val defaultForCurrency: Boolean,
    val status: String?
)

@JsonClass(generateAdapter = true)
data class ExternalAccountsResponse(
    @Json(name = "external_accounts")
    val externalAccounts: List<ExternalAccount>
)

@JsonClass(generateAdapter = true)
data class CreateExternalAccountRequest(
    val token: String
)
