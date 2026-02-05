package com.example.stripedemo.data.models

import com.google.gson.annotations.SerializedName

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
