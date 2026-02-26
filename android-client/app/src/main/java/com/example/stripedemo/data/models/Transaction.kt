package com.example.stripedemo.data.models

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class PayUserRequest(
    val amount: Int,
    val currency: String = "usd",
    @Json(name = "recipient_account_id")
    val recipientAccountId: String,
    @Json(name = "payment_method_id")
    val paymentMethodId: String
)

@JsonClass(generateAdapter = true)
data class PayUserResponse(
    val id: String,
    val amount: Int,
    val currency: String,
    val status: String,
    val recipient: String,
    val transfer: String?,
    val created: Long
)

@JsonClass(generateAdapter = true)
data class CreatePaymentIntentRequest(
    val amount: Int,
    val currency: String = "usd",
    @Json(name = "recipient_account_id")
    val recipientAccountId: String,
    @Json(name = "save_payment_method")
    val savePaymentMethod: Boolean
)

@JsonClass(generateAdapter = true)
data class CreatePaymentIntentResponse(
    @Json(name = "client_secret")
    val clientSecret: String,
    @Json(name = "payment_intent_id")
    val paymentIntentId: String,
    val amount: Int,
    val currency: String,
    val recipient: String
)
