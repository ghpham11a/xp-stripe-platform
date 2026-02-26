package com.example.stripedemo.data.models

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class AccountLinkRequest(
    @Json(name = "refresh_url")
    val refreshUrl: String,
    @Json(name = "return_url")
    val returnUrl: String
)

@JsonClass(generateAdapter = true)
data class AccountLinkResponse(
    val url: String,
    val created: String,
    @Json(name = "expires_at")
    val expiresAt: String
)
