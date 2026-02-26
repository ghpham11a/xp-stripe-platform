package com.example.stripedemo.features.bankaccounts

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.stripedemo.data.models.Account
import com.example.stripedemo.data.models.ExternalAccount
import com.example.stripedemo.data.repositories.accounts.AccountRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class BankAccountsUiState(
    val account: Account? = null,
    val externalAccounts: List<ExternalAccount> = emptyList(),
    val isLoading: Boolean = false,
    val isLoadingAccounts: Boolean = false,
    val errorMessage: String? = null,
    val successMessage: String? = null,
    val showBankAccountForm: Boolean = false
)

@HiltViewModel
class BankAccountsViewModel @Inject constructor(
    private val accountRepository: AccountRepository,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val accountId: String = savedStateHandle.get<String>("accountId") ?: ""

    private val _uiState = MutableStateFlow(BankAccountsUiState())
    val uiState: StateFlow<BankAccountsUiState> = _uiState.asStateFlow()

    init {
        loadAccount()
        loadExternalAccounts()
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

    fun loadExternalAccounts() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingAccounts = true) }
            accountRepository.listExternalAccounts(accountId)
                .onSuccess { externalAccounts ->
                    _uiState.update { it.copy(externalAccounts = externalAccounts, isLoadingAccounts = false) }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isLoadingAccounts = false, errorMessage = error.message) }
                }
        }
    }

    fun showBankAccountForm() {
        _uiState.update { it.copy(showBankAccountForm = true) }
    }

    fun hideBankAccountForm() {
        _uiState.update { it.copy(showBankAccountForm = false) }
    }

    fun createBankAccount(
        accountHolderName: String,
        routingNumber: String,
        accountNumber: String
    ) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }

            // First create the bank account token via Stripe API
            accountRepository.createBankAccountToken(
                accountHolderName = accountHolderName,
                routingNumber = routingNumber,
                accountNumber = accountNumber
            )
                .onSuccess { token ->
                    // Then create the external account with the token
                    accountRepository.createExternalAccount(accountId, token)
                        .onSuccess {
                            _uiState.update {
                                it.copy(
                                    isLoading = false,
                                    showBankAccountForm = false,
                                    successMessage = "Bank account added successfully"
                                )
                            }
                            loadExternalAccounts()
                        }
                        .onFailure { error ->
                            _uiState.update { it.copy(isLoading = false, errorMessage = error.message) }
                        }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isLoading = false, errorMessage = error.message) }
                }
        }
    }

    fun deleteExternalAccount(externalAccountId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }
            accountRepository.deleteExternalAccount(accountId, externalAccountId)
                .onSuccess {
                    _uiState.update { it.copy(isLoading = false, successMessage = "Bank account removed") }
                    loadExternalAccounts()
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isLoading = false, errorMessage = error.message) }
                }
        }
    }

    fun setDefaultExternalAccount(externalAccountId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorMessage = null) }
            accountRepository.setDefaultExternalAccount(accountId, externalAccountId)
                .onSuccess {
                    _uiState.update { it.copy(isLoading = false, successMessage = "Default bank account updated") }
                    loadExternalAccounts()
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
