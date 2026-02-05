package com.example.stripedemo.data.models

import com.google.gson.annotations.SerializedName

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
