package com.example.stripedemo.data.models

import com.google.gson.annotations.SerializedName

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
