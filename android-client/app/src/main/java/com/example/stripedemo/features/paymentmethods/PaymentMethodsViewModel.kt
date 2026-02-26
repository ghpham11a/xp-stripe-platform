package com.example.stripedemo.features.paymentmethods

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.stripedemo.data.models.Account
import com.example.stripedemo.data.models.PaymentMethod
import com.example.stripedemo.data.repositories.accounts.AccountRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class PaymentMethodsUiState(
    val account: Account? = null,
    val paymentMethods: List<PaymentMethod> = emptyList(),
    val isLoading: Boolean = false,
    val isLoadingMethods: Boolean = false,
    val errorMessage: String? = null,
    val successMessage: String? = null,
    val showAddCardSection: Boolean = false,
    val setupIntentClientSecret: String? = null
)

@HiltViewModel
class PaymentMethodsViewModel @Inject constructor(
    private val accountRepository: AccountRepository,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val accountId: String = savedStateHandle.get<String>("accountId") ?: ""

    private val _uiState = MutableStateFlow(PaymentMethodsUiState())
    val uiState: StateFlow<PaymentMethodsUiState> = _uiState.asStateFlow()

    init {
        loadAccount()
        loadPaymentMethods()
    }

    private fun loadAccount() {
        viewModelScope.launch {
            accountRepository.getAccount(accountId)
                .onSuccess { account ->
                    _uiState.update { it.copy(account = account) }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(errorMessage = error.message) }
                }
        }
    }

    fun loadPaymentMethods() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingMethods = true) }
            accountRepository.listPaymentMethods(accountId)
                .onSuccess { paymentMethods ->
                    _uiState.update { it.copy(paymentMethods = paymentMethods, isLoadingMethods = false) }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isLoadingMethods = false, errorMessage = error.message) }
                }
        }
    }

    fun showAddCardSection() {
        _uiState.update { it.copy(showAddCardSection = true) }
    }

    fun hideAddCardSection() {
        _uiState.update { it.copy(showAddCardSection = false) }
    }

    fun createSetupIntent() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }
            accountRepository.createSetupIntent(
                accountId = accountId,
                customerId = _uiState.value.account?.stripeCustomerId
            )
                .onSuccess { setupIntent ->
                    _uiState.update { it.copy(isLoading = false, setupIntentClientSecret = setupIntent.clientSecret) }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isLoading = false, errorMessage = error.message) }
                }
        }
    }

    fun clearSetupIntent() {
        _uiState.update { it.copy(setupIntentClientSecret = null) }
    }

    fun onSetupIntentConfirmed() {
        _uiState.update {
            it.copy(
                setupIntentClientSecret = null,
                showAddCardSection = false,
                successMessage = "Card added successfully"
            )
        }
        loadPaymentMethods()
    }

    fun deletePaymentMethod(paymentMethodId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }
            accountRepository.deletePaymentMethod(accountId, paymentMethodId)
                .onSuccess {
                    _uiState.update { it.copy(isLoading = false, successMessage = "Payment method removed") }
                    loadPaymentMethods()
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isLoading = false, errorMessage = error.message) }
                }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(errorMessage = null) }
    }

    fun clearSuccessMessage() {
        _uiState.update { it.copy(successMessage = null) }
    }
}
