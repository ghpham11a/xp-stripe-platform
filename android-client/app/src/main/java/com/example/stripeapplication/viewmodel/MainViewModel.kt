package com.example.stripeapplication.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.stripeapplication.data.models.*
import com.example.stripeapplication.data.repository.AccountRepository
import com.example.stripeapplication.data.repository.Result
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class UiState(
    val accounts: List<Account> = emptyList(),
    val selectedAccount: Account? = null,
    val paymentMethods: List<PaymentMethod> = emptyList(),
    val externalAccounts: List<ExternalAccount> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val successMessage: String? = null,
    val setupIntentClientSecret: String? = null,
    val paymentIntentClientSecret: String? = null,
    val onboardingUrl: String? = null
)

class MainViewModel : ViewModel() {
    private val repository = AccountRepository()

    private val _uiState = MutableStateFlow(UiState())
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    init {
        loadAccounts()
    }

    fun loadAccounts() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            when (val result = repository.listAccounts()) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        accounts = result.data,
                        isLoading = false
                    )
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(
                        error = result.message,
                        isLoading = false
                    )
                }
            }
        }
    }

    fun createAccount(name: String, email: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            when (val result = repository.createAccount(name, email)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        selectedAccount = result.data,
                        successMessage = "Account created successfully",
                        isLoading = false
                    )
                    loadAccounts()
                    loadAccountData(result.data.id)
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(
                        error = result.message,
                        isLoading = false
                    )
                }
            }
        }
    }

    fun selectAccount(account: Account) {
        _uiState.value = _uiState.value.copy(selectedAccount = account)
        loadAccountData(account.id)
    }

    fun loadAccountData(accountId: String) {
        viewModelScope.launch {
            // Load account details
            when (val result = repository.getAccount(accountId)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(selectedAccount = result.data)
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(error = result.message)
                }
            }
        }
        loadPaymentMethods(accountId)
        loadExternalAccounts(accountId)
    }

    fun deleteAccount(accountId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            when (val result = repository.deleteAccount(accountId)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        selectedAccount = null,
                        paymentMethods = emptyList(),
                        externalAccounts = emptyList(),
                        successMessage = "Account deleted successfully",
                        isLoading = false
                    )
                    loadAccounts()
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(
                        error = result.message,
                        isLoading = false
                    )
                }
            }
        }
    }

    fun upgradeToRecipient(accountId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            when (val result = repository.upgradeToRecipient(accountId)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        successMessage = "Account upgraded to recipient",
                        isLoading = false
                    )
                    loadAccountData(accountId)
                    loadAccounts()
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(
                        error = result.message,
                        isLoading = false
                    )
                }
            }
        }
    }

    fun createOnboardingLink(accountId: String, refreshUrl: String, returnUrl: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            when (val result = repository.createOnboardingLink(accountId, refreshUrl, returnUrl)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        onboardingUrl = result.data.url,
                        isLoading = false
                    )
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(
                        error = result.message,
                        isLoading = false
                    )
                }
            }
        }
    }

    fun clearOnboardingUrl() {
        _uiState.value = _uiState.value.copy(onboardingUrl = null)
    }

    // Payment Methods
    fun loadPaymentMethods(accountId: String) {
        viewModelScope.launch {
            when (val result = repository.listPaymentMethods(accountId)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(paymentMethods = result.data)
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(error = result.message)
                }
            }
        }
    }

    fun createSetupIntent(accountId: String, customerId: String? = null) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            when (val result = repository.createSetupIntent(accountId, customerId)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        setupIntentClientSecret = result.data.clientSecret,
                        isLoading = false
                    )
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(
                        error = result.message,
                        isLoading = false
                    )
                }
            }
        }
    }

    fun clearSetupIntent() {
        _uiState.value = _uiState.value.copy(setupIntentClientSecret = null)
    }

    fun onSetupIntentConfirmed(accountId: String) {
        _uiState.value = _uiState.value.copy(
            setupIntentClientSecret = null,
            successMessage = "Card added successfully"
        )
        loadPaymentMethods(accountId)
    }

    fun deletePaymentMethod(accountId: String, paymentMethodId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            when (val result = repository.deletePaymentMethod(accountId, paymentMethodId)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        successMessage = "Payment method removed",
                        isLoading = false
                    )
                    loadPaymentMethods(accountId)
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(
                        error = result.message,
                        isLoading = false
                    )
                }
            }
        }
    }

    // External Accounts
    fun loadExternalAccounts(accountId: String) {
        viewModelScope.launch {
            when (val result = repository.listExternalAccounts(accountId)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(externalAccounts = result.data)
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(error = result.message)
                }
            }
        }
    }

    fun createExternalAccount(accountId: String, token: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            when (val result = repository.createExternalAccount(accountId, token)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        successMessage = "Bank account added successfully",
                        isLoading = false
                    )
                    loadExternalAccounts(accountId)
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(
                        error = result.message,
                        isLoading = false
                    )
                }
            }
        }
    }

    fun deleteExternalAccount(accountId: String, externalAccountId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            when (val result = repository.deleteExternalAccount(accountId, externalAccountId)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        successMessage = "Bank account removed",
                        isLoading = false
                    )
                    loadExternalAccounts(accountId)
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(
                        error = result.message,
                        isLoading = false
                    )
                }
            }
        }
    }

    fun setDefaultExternalAccount(accountId: String, externalAccountId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            when (val result = repository.setDefaultExternalAccount(accountId, externalAccountId)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        successMessage = "Default bank account updated",
                        isLoading = false
                    )
                    loadExternalAccounts(accountId)
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(
                        error = result.message,
                        isLoading = false
                    )
                }
            }
        }
    }

    // Transactions
    fun payUser(
        accountId: String,
        recipientAccountId: String,
        paymentMethodId: String,
        amount: Int
    ) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            when (val result = repository.payUser(accountId, recipientAccountId, paymentMethodId, amount)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        successMessage = "Payment of $${amount / 100.0} sent successfully!",
                        isLoading = false
                    )
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(
                        error = result.message,
                        isLoading = false
                    )
                }
            }
        }
    }

    fun createPaymentIntent(
        accountId: String,
        recipientAccountId: String,
        amount: Int,
        savePaymentMethod: Boolean
    ) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            when (val result = repository.createPaymentIntent(accountId, recipientAccountId, amount, savePaymentMethod)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        paymentIntentClientSecret = result.data.clientSecret,
                        isLoading = false
                    )
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(
                        error = result.message,
                        isLoading = false
                    )
                }
            }
        }
    }

    fun clearPaymentIntent() {
        _uiState.value = _uiState.value.copy(paymentIntentClientSecret = null)
    }

    fun onPaymentIntentConfirmed(accountId: String) {
        _uiState.value = _uiState.value.copy(
            paymentIntentClientSecret = null,
            successMessage = "Payment completed successfully!"
        )
        loadPaymentMethods(accountId)
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }

    fun clearSuccessMessage() {
        _uiState.value = _uiState.value.copy(successMessage = null)
    }
}
