package com.example.stripedemo.features.paymentmethods

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.stripedemo.data.models.Account
import com.example.stripedemo.data.models.PaymentMethod
import com.example.stripedemo.data.repositories.AccountRepository
import com.example.stripedemo.data.repositories.Result
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
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
            when (val result = accountRepository.getAccount(accountId)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(account = result.data)
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(errorMessage = result.message)
                }
            }
        }
    }

    fun loadPaymentMethods() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingMethods = true)
            when (val result = accountRepository.listPaymentMethods(accountId)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        paymentMethods = result.data,
                        isLoadingMethods = false
                    )
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(
                        isLoadingMethods = false,
                        errorMessage = result.message
                    )
                }
            }
        }
    }

    fun showAddCardSection() {
        _uiState.value = _uiState.value.copy(showAddCardSection = true)
    }

    fun hideAddCardSection() {
        _uiState.value = _uiState.value.copy(showAddCardSection = false)
    }

    fun createSetupIntent() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
            when (val result = accountRepository.createSetupIntent(
                accountId = accountId,
                customerId = _uiState.value.account?.stripeCustomerId
            )) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        setupIntentClientSecret = result.data.clientSecret
                    )
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        errorMessage = result.message
                    )
                }
            }
        }
    }

    fun clearSetupIntent() {
        _uiState.value = _uiState.value.copy(setupIntentClientSecret = null)
    }

    fun onSetupIntentConfirmed() {
        _uiState.value = _uiState.value.copy(
            setupIntentClientSecret = null,
            showAddCardSection = false,
            successMessage = "Card added successfully"
        )
        loadPaymentMethods()
    }

    fun deletePaymentMethod(paymentMethodId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
            when (val result = accountRepository.deletePaymentMethod(accountId, paymentMethodId)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        successMessage = "Payment method removed"
                    )
                    loadPaymentMethods()
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        errorMessage = result.message
                    )
                }
            }
        }
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(errorMessage = null)
    }

    fun clearSuccessMessage() {
        _uiState.value = _uiState.value.copy(successMessage = null)
    }
}
