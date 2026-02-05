package com.example.stripedemo.data.models

import com.google.gson.annotations.SerializedName

data class AccountLinkRequest(
    @SerializedName("refresh_url")
    val refreshUrl: String,
    @SerializedName("return_url")
    val returnUrl: String
)

data class AccountLinkResponse(
    val url: String,
    val created: String,
    @SerializedName("expires_at")
    val expiresAt: String
)
