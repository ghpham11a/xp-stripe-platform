package com.example.stripedemo.features.bankaccounts

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.stripedemo.data.models.Account
import com.example.stripedemo.data.models.ExternalAccount
import com.example.stripedemo.data.repositories.AccountRepository
import com.example.stripedemo.data.repositories.Result
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
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

    fun loadExternalAccounts() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingAccounts = true)
            when (val result = accountRepository.listExternalAccounts(accountId)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        externalAccounts = result.data,
                        isLoadingAccounts = false
                    )
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(
                        isLoadingAccounts = false,
                        errorMessage = result.message
                    )
                }
            }
        }
    }

    fun showBankAccountForm() {
        _uiState.value = _uiState.value.copy(showBankAccountForm = true)
    }

    fun hideBankAccountForm() {
        _uiState.value = _uiState.value.copy(showBankAccountForm = false)
    }

    fun createBankAccount(
        accountHolderName: String,
        routingNumber: String,
        accountNumber: String
    ) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)

            // First create the bank account token via Stripe API
            when (val tokenResult = accountRepository.createBankAccountToken(
                accountHolderName = accountHolderName,
                routingNumber = routingNumber,
                accountNumber = accountNumber
            )) {
                is Result.Success -> {
                    // Then create the external account with the token
                    when (val result = accountRepository.createExternalAccount(accountId, tokenResult.data)) {
                        is Result.Success -> {
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                showBankAccountForm = false,
                                successMessage = "Bank account added successfully"
                            )
                            loadExternalAccounts()
                        }
                        is Result.Error -> {
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                errorMessage = result.message
                            )
                        }
                    }
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        errorMessage = tokenResult.message
                    )
                }
            }
        }
    }

    fun deleteExternalAccount(externalAccountId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
            when (val result = accountRepository.deleteExternalAccount(accountId, externalAccountId)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        successMessage = "Bank account removed"
                    )
                    loadExternalAccounts()
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

    fun setDefaultExternalAccount(externalAccountId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, errorMessage = null)
            when (val result = accountRepository.setDefaultExternalAccount(accountId, externalAccountId)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        successMessage = "Default bank account updated"
                    )
                    loadExternalAccounts()
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
