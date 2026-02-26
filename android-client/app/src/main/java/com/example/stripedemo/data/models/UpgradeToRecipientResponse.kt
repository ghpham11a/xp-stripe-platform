package com.example.stripedemo.data.models

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class UpgradeToRecipientResponse(
    val id: String,
    @Json(name = "stripe_account_id")
    val stripeAccountId: String,
    @Json(name = "is_merchant")
    val isMerchant: Boolean,
    @Json(name = "is_recipient")
    val isRecipient: Boolean,
    @Json(name = "merchant_capabilities")
    val merchantCapabilities: Map<String, Any?>?,
    @Json(name = "recipient_capabilities")
    val recipientCapabilities: Map<String, Any?>?
)
