package com.example.stripedemo.data.networking

import com.example.stripedemo.data.models.*
import retrofit2.Response
import retrofit2.http.*

interface ApiService {

    // Account APIs
    @POST("api/accounts")
    suspend fun createAccount(@Body request: CreateAccountRequest): Response<Account>

    @GET("api/accounts")
    suspend fun listAccounts(): Response<AccountsResponse>

    @GET("api/accounts/{accountId}")
    suspend fun getAccount(@Path("accountId") accountId: String): Response<Account>

    @DELETE("api/accounts/{accountId}")
    suspend fun deleteAccount(@Path("accountId") accountId: String): Response<Unit>

    @POST("api/accounts/{accountId}/upgrade-to-recipient")
    suspend fun upgradeToRecipient(@Path("accountId") accountId: String): Response<UpgradeToRecipientResponse>

    @POST("api/accounts/{accountId}/onboarding-link")
    suspend fun createOnboardingLink(
        @Path("accountId") accountId: String,
        @Body request: AccountLinkRequest
    ): Response<AccountLinkResponse>

    // Payment Method APIs
    @POST("api/accounts/{accountId}/payment-methods/setup-intent")
    suspend fun createSetupIntent(
        @Path("accountId") accountId: String,
        @Query("customer_id") customerId: String? = null
    ): Response<SetupIntentResponse>

    @GET("api/accounts/{accountId}/payment-methods")
    suspend fun listPaymentMethods(@Path("accountId") accountId: String): Response<PaymentMethodsResponse>

    @DELETE("api/accounts/{accountId}/payment-methods/{paymentMethodId}")
    suspend fun deletePaymentMethod(
        @Path("accountId") accountId: String,
        @Path("paymentMethodId") paymentMethodId: String
    ): Response<Unit>

    // External Account APIs
    @POST("api/accounts/{accountId}/external-accounts")
    suspend fun createExternalAccount(
        @Path("accountId") accountId: String,
        @Body request: CreateExternalAccountRequest
    ): Response<ExternalAccount>

    @GET("api/accounts/{accountId}/external-accounts")
    suspend fun listExternalAccounts(@Path("accountId") accountId: String): Response<ExternalAccountsResponse>

    @DELETE("api/accounts/{accountId}/external-accounts/{externalAccountId}")
    suspend fun deleteExternalAccount(
        @Path("accountId") accountId: String,
        @Path("externalAccountId") externalAccountId: String
    ): Response<Unit>

    @PATCH("api/accounts/{accountId}/external-accounts/{externalAccountId}/default")
    suspend fun setDefaultExternalAccount(
        @Path("accountId") accountId: String,
        @Path("externalAccountId") externalAccountId: String
    ): Response<ExternalAccount>

    // Transaction APIs
    @POST("api/transactions/{accountId}/pay-user")
    suspend fun payUser(
        @Path("accountId") accountId: String,
        @Body request: PayUserRequest
    ): Response<PayUserResponse>

    @POST("api/transactions/{accountId}/create-payment-intent")
    suspend fun createPaymentIntent(
        @Path("accountId") accountId: String,
        @Body request: CreatePaymentIntentRequest
    ): Response<CreatePaymentIntentResponse>
}