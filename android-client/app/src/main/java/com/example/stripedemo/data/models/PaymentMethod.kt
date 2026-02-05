package com.example.stripedemo.data.models

import com.google.gson.annotations.SerializedName

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
