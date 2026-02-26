package com.example.stripedemo.data.repositories.accounts

import com.example.stripedemo.data.models.Account
import com.example.stripedemo.data.models.AccountLinkRequest
import com.example.stripedemo.data.models.AccountLinkResponse
import com.example.stripedemo.data.models.AccountsResponse
import com.example.stripedemo.data.models.CreateAccountRequest
import com.example.stripedemo.data.models.CreateExternalAccountRequest
import com.example.stripedemo.data.models.CreatePaymentIntentRequest
import com.example.stripedemo.data.models.CreatePaymentIntentResponse
import com.example.stripedemo.data.models.ExternalAccount
import com.example.stripedemo.data.models.ExternalAccountsResponse
import com.example.stripedemo.data.models.PayUserRequest
import com.example.stripedemo.data.models.PayUserResponse
import com.example.stripedemo.data.models.PaymentMethodsResponse
import com.example.stripedemo.data.models.SetupIntentResponse
import com.example.stripedemo.data.models.UpgradeToRecipientResponse
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.PATCH
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query

interface AccountsEndpoints {

    // Account APIs
    @POST("api/accounts")
    suspend fun createAccount(@Body request: CreateAccountRequest): Account

    @GET("api/accounts")
    suspend fun listAccounts(): AccountsResponse

    @GET("api/accounts/{accountId}")
    suspend fun getAccount(@Path("accountId") accountId: String): Account

    @DELETE("api/accounts/{accountId}")
    suspend fun deleteAccount(@Path("accountId") accountId: String)

    @POST("api/accounts/{accountId}/upgrade-to-recipient")
    suspend fun upgradeToRecipient(@Path("accountId") accountId: String): UpgradeToRecipientResponse

    @POST("api/accounts/{accountId}/onboarding-link")
    suspend fun createOnboardingLink(
        @Path("accountId") accountId: String,
        @Body request: AccountLinkRequest
    ): AccountLinkResponse

    // Payment Method APIs
    @POST("api/accounts/{accountId}/payment-methods/setup-intent")
    suspend fun createSetupIntent(
        @Path("accountId") accountId: String,
        @Query("customer_id") customerId: String? = null
    ): SetupIntentResponse

    @GET("api/accounts/{accountId}/payment-methods")
    suspend fun listPaymentMethods(@Path("accountId") accountId: String): PaymentMethodsResponse

    @DELETE("api/accounts/{accountId}/payment-methods/{paymentMethodId}")
    suspend fun deletePaymentMethod(
        @Path("accountId") accountId: String,
        @Path("paymentMethodId") paymentMethodId: String
    )

    // External Account APIs
    @POST("api/accounts/{accountId}/external-accounts")
    suspend fun createExternalAccount(
        @Path("accountId") accountId: String,
        @Body request: CreateExternalAccountRequest
    ): ExternalAccount

    @GET("api/accounts/{accountId}/external-accounts")
    suspend fun listExternalAccounts(@Path("accountId") accountId: String): ExternalAccountsResponse

    @DELETE("api/accounts/{accountId}/external-accounts/{externalAccountId}")
    suspend fun deleteExternalAccount(
        @Path("accountId") accountId: String,
        @Path("externalAccountId") externalAccountId: String
    )

    @PATCH("api/accounts/{accountId}/external-accounts/{externalAccountId}/default")
    suspend fun setDefaultExternalAccount(
        @Path("accountId") accountId: String,
        @Path("externalAccountId") externalAccountId: String
    ): ExternalAccount

    // Transaction APIs
    @POST("api/transactions/{accountId}/pay-user")
    suspend fun payUser(
        @Path("accountId") accountId: String,
        @Body request: PayUserRequest
    ): PayUserResponse

    @POST("api/transactions/{accountId}/create-payment-intent")
    suspend fun createPaymentIntent(
        @Path("accountId") accountId: String,
        @Body request: CreatePaymentIntentRequest
    ): CreatePaymentIntentResponse
}
