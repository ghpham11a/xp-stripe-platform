package com.example.stripeapplication.data.repository

import com.example.stripeapplication.data.api.ApiClient
import com.example.stripeapplication.data.models.*
import com.google.gson.Gson
import retrofit2.Response

sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Error(val message: String) : Result<Nothing>()
}

class AccountRepository {
    private val api = ApiClient.apiService
    private val gson = Gson()

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
}
