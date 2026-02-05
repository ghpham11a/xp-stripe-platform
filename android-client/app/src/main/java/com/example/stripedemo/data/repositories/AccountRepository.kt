package com.example.stripedemo.data.repositories

import com.example.stripedemo.BuildConfig
import com.example.stripedemo.data.models.*
import com.example.stripedemo.data.networking.ApiService
import com.google.gson.Gson
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.FormBody
import okhttp3.OkHttpClient
import okhttp3.Request
import retrofit2.Response
import javax.inject.Inject

class AccountRepository @Inject constructor(
    private val api: ApiService,
    private val gson: Gson,
    private val okHttpClient: OkHttpClient
) {
    private suspend fun <T> handleResponse(response: Response<T>): Result<T> {
        return if (response.isSuccessful) {
            response.body()?.let {
                Result.Success(it)
            } ?: Result.Error("Empty response")
        } else {
            val errorBody = response.errorBody()?.string()
            val errorMessage = try {
                gson.fromJson(errorBody, ErrorResponse::class.java)?.detail ?: "Unknown error"
            } catch (e: Exception) {
                "HTTP ${response.code()}"
            }
            Result.Error(errorMessage)
        }
    }

    // Account operations
    suspend fun createAccount(name: String, email: String, country: String = "US"): Result<Account> {
        return handleResponse(api.createAccount(CreateAccountRequest(name, email, country)))
    }

    suspend fun listAccounts(): Result<List<Account>> {
        return when (val result = handleResponse(api.listAccounts())) {
            is Result.Success -> Result.Success(result.data.accounts)
            is Result.Error -> result
        }
    }

    suspend fun getAccount(accountId: String): Result<Account> {
        return handleResponse(api.getAccount(accountId))
    }

    suspend fun deleteAccount(accountId: String): Result<Unit> {
        return handleResponse(api.deleteAccount(accountId))
    }

    suspend fun upgradeToRecipient(accountId: String): Result<UpgradeToRecipientResponse> {
        return handleResponse(api.upgradeToRecipient(accountId))
    }

    suspend fun createOnboardingLink(
        accountId: String,
        refreshUrl: String,
        returnUrl: String
    ): Result<AccountLinkResponse> {
        return handleResponse(
            api.createOnboardingLink(accountId, AccountLinkRequest(refreshUrl, returnUrl))
        )
    }

    // Payment Method operations
    suspend fun createSetupIntent(accountId: String, customerId: String? = null): Result<SetupIntentResponse> {
        return handleResponse(api.createSetupIntent(accountId, customerId))
    }

    suspend fun listPaymentMethods(accountId: String): Result<List<PaymentMethod>> {
        return when (val result = handleResponse(api.listPaymentMethods(accountId))) {
            is Result.Success -> Result.Success(result.data.paymentMethods)
            is Result.Error -> result
        }
    }

    suspend fun deletePaymentMethod(accountId: String, paymentMethodId: String): Result<Unit> {
        return handleResponse(api.deletePaymentMethod(accountId, paymentMethodId))
    }

    // External Account operations
    suspend fun createExternalAccount(accountId: String, token: String): Result<ExternalAccount> {
        return handleResponse(api.createExternalAccount(accountId, CreateExternalAccountRequest(token)))
    }

    suspend fun listExternalAccounts(accountId: String): Result<List<ExternalAccount>> {
        return when (val result = handleResponse(api.listExternalAccounts(accountId))) {
            is Result.Success -> Result.Success(result.data.externalAccounts)
            is Result.Error -> result
        }
    }

    suspend fun deleteExternalAccount(accountId: String, externalAccountId: String): Result<Unit> {
        return handleResponse(api.deleteExternalAccount(accountId, externalAccountId))
    }

    suspend fun setDefaultExternalAccount(accountId: String, externalAccountId: String): Result<ExternalAccount> {
        return handleResponse(api.setDefaultExternalAccount(accountId, externalAccountId))
    }

    // Transaction operations
    suspend fun payUser(
        accountId: String,
        recipientAccountId: String,
        paymentMethodId: String,
        amount: Int,
        currency: String = "usd"
    ): Result<PayUserResponse> {
        return handleResponse(
            api.payUser(accountId, PayUserRequest(amount, currency, recipientAccountId, paymentMethodId))
        )
    }

    suspend fun createPaymentIntent(
        accountId: String,
        recipientAccountId: String,
        amount: Int,
        savePaymentMethod: Boolean,
        currency: String = "usd"
    ): Result<CreatePaymentIntentResponse> {
        return handleResponse(
            api.createPaymentIntent(
                accountId,
                CreatePaymentIntentRequest(amount, currency, recipientAccountId, savePaymentMethod)
            )
        )
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
                val json = gson.fromJson(responseBody, Map::class.java)
                val tokenId = json["id"] as? String
                if (tokenId != null) {
                    Result.Success(tokenId)
                } else {
                    Result.Error("Failed to parse token response")
                }
            } else {
                val json = responseBody?.let { gson.fromJson(it, Map::class.java) }
                val error = json?.get("error") as? Map<*, *>
                val message = error?.get("message") as? String ?: "Failed to create bank token"
                Result.Error(message)
            }
        } catch (e: Exception) {
            Result.Error(e.message ?: "Network error")
        }
    }
}
