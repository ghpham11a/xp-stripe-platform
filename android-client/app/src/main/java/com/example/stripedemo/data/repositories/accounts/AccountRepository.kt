package com.example.stripedemo.data.repositories.accounts

import com.example.stripedemo.BuildConfig
import com.example.stripedemo.data.models.Account
import com.example.stripedemo.data.models.AccountLinkRequest
import com.example.stripedemo.data.models.AccountLinkResponse
import com.example.stripedemo.data.models.CreateAccountRequest
import com.example.stripedemo.data.models.CreateExternalAccountRequest
import com.example.stripedemo.data.models.CreatePaymentIntentRequest
import com.example.stripedemo.data.models.CreatePaymentIntentResponse
import com.example.stripedemo.data.models.ExternalAccount
import com.example.stripedemo.data.models.PayUserRequest
import com.example.stripedemo.data.models.PayUserResponse
import com.example.stripedemo.data.models.PaymentMethod
import com.example.stripedemo.data.models.SetupIntentResponse
import com.example.stripedemo.data.models.UpgradeToRecipientResponse
import com.squareup.moshi.Moshi
import com.squareup.moshi.Types
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.FormBody
import okhttp3.OkHttpClient
import okhttp3.Request
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AccountRepository @Inject constructor(
    private val accountsEndpoints: AccountsEndpoints,
    private val moshi: Moshi,
    private val okHttpClient: OkHttpClient
) {
    // Account operations
    suspend fun createAccount(name: String, email: String, country: String = "US"): Result<Account> {
        return try {
            val response = accountsEndpoints.createAccount(CreateAccountRequest(name, email, country))
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun listAccounts(): Result<List<Account>> {
        return try {
            val response = accountsEndpoints.listAccounts()
            Result.success(response.accounts)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getAccount(accountId: String): Result<Account> {
        return try {
            val response = accountsEndpoints.getAccount(accountId)
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deleteAccount(accountId: String): Result<Unit> {
        return try {
            accountsEndpoints.deleteAccount(accountId)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun upgradeToRecipient(accountId: String): Result<UpgradeToRecipientResponse> {
        return try {
            val response = accountsEndpoints.upgradeToRecipient(accountId)
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun createOnboardingLink(
        accountId: String,
        refreshUrl: String,
        returnUrl: String
    ): Result<AccountLinkResponse> {
        return try {
            val response = accountsEndpoints.createOnboardingLink(
                accountId,
                AccountLinkRequest(refreshUrl, returnUrl)
            )
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // Payment Method operations
    suspend fun createSetupIntent(accountId: String, customerId: String? = null): Result<SetupIntentResponse> {
        return try {
            val response = accountsEndpoints.createSetupIntent(accountId, customerId)
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun listPaymentMethods(accountId: String): Result<List<PaymentMethod>> {
        return try {
            val response = accountsEndpoints.listPaymentMethods(accountId)
            Result.success(response.paymentMethods)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deletePaymentMethod(accountId: String, paymentMethodId: String): Result<Unit> {
        return try {
            accountsEndpoints.deletePaymentMethod(accountId, paymentMethodId)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // External Account operations
    suspend fun createExternalAccount(accountId: String, token: String): Result<ExternalAccount> {
        return try {
            val response = accountsEndpoints.createExternalAccount(
                accountId,
                CreateExternalAccountRequest(token)
            )
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun listExternalAccounts(accountId: String): Result<List<ExternalAccount>> {
        return try {
            val response = accountsEndpoints.listExternalAccounts(accountId)
            Result.success(response.externalAccounts)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deleteExternalAccount(accountId: String, externalAccountId: String): Result<Unit> {
        return try {
            accountsEndpoints.deleteExternalAccount(accountId, externalAccountId)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun setDefaultExternalAccount(accountId: String, externalAccountId: String): Result<ExternalAccount> {
        return try {
            val response = accountsEndpoints.setDefaultExternalAccount(accountId, externalAccountId)
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // Transaction operations
    suspend fun payUser(
        accountId: String,
        recipientAccountId: String,
        paymentMethodId: String,
        amount: Int,
        currency: String = "usd"
    ): Result<PayUserResponse> {
        return try {
            val response = accountsEndpoints.payUser(
                accountId,
                PayUserRequest(amount, currency, recipientAccountId, paymentMethodId)
            )
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun createPaymentIntent(
        accountId: String,
        recipientAccountId: String,
        amount: Int,
        savePaymentMethod: Boolean,
        currency: String = "usd"
    ): Result<CreatePaymentIntentResponse> {
        return try {
            val response = accountsEndpoints.createPaymentIntent(
                accountId,
                CreatePaymentIntentRequest(amount, currency, recipientAccountId, savePaymentMethod)
            )
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // Bank account token creation via direct Stripe API call
    suspend fun createBankAccountToken(
        accountHolderName: String,
        routingNumber: String,
        accountNumber: String
    ): Result<String> = withContext(Dispatchers.IO) {
        try {
            val formBody = FormBody.Builder()
                .add("bank_account[country]", "US")
                .add("bank_account[currency]", "usd")
                .add("bank_account[routing_number]", routingNumber)
                .add("bank_account[account_number]", accountNumber)
                .add("bank_account[account_holder_name]", accountHolderName)
                .add("bank_account[account_holder_type]", "individual")
                .build()

            val request = Request.Builder()
                .url("https://api.stripe.com/v1/tokens")
                .addHeader("Authorization", "Bearer ${BuildConfig.STRIPE_PUBLISHABLE_KEY}")
                .addHeader("Content-Type", "application/x-www-form-urlencoded")
                .post(formBody)
                .build()

            val response = okHttpClient.newCall(request).execute()
            val responseBody = response.body?.string()

            if (response.isSuccessful && responseBody != null) {
                val mapAdapter = moshi.adapter<Map<String, Any?>>(
                    Types.newParameterizedType(
                        Map::class.java, String::class.java, Any::class.java
                    )
                )
                val json = mapAdapter.fromJson(responseBody)
                val tokenId = json?.get("id") as? String
                    ?: throw Exception("Failed to parse token response")
                Result.success(tokenId)
            } else {
                val mapAdapter = moshi.adapter<Map<String, Any?>>(
                    Types.newParameterizedType(
                        Map::class.java, String::class.java, Any::class.java
                    )
                )
                val json = responseBody?.let { mapAdapter.fromJson(it) }

                @Suppress("UNCHECKED_CAST")
                val error = json?.get("error") as? Map<String, Any?>
                val message = error?.get("message") as? String ?: "Failed to create bank token"
                Result.failure(Exception(message))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
