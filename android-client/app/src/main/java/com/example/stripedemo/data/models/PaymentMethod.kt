package com.example.stripedemo.data.models

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class CardDetails(
    val brand: String,
    val last4: String,
    @Json(name = "exp_month")
    val expMonth: Int,
    @Json(name = "exp_year")
    val expYear: Int
)

@JsonClass(generateAdapter = true)
data class PaymentMethod(
    val id: String,
    val type: String,
    val card: CardDetails?,
    val created: Long
)

@JsonClass(generateAdapter = true)
data class PaymentMethodsResponse(
    @Json(name = "payment_methods")
    val paymentMethods: List<PaymentMethod>
)

@JsonClass(generateAdapter = true)
data class SetupIntentResponse(
    @Json(name = "client_secret")
    val clientSecret: String,
    @Json(name = "setup_intent_id")
    val setupIntentId: String,
    @Json(name = "customer_id")
    val customerId: String? = null
)
