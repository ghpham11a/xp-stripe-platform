package com.example.stripedemo.features.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.stripedemo.data.models.Account
import com.example.stripedemo.data.repositories.AccountRepository
import com.example.stripedemo.data.repositories.Result
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class HomeUiState(
    val accounts: List<Account> = emptyList(),
    val selectedAccount: Account? = null,
    val isLoadingAccounts: Boolean = false,
    val isCreatingAccount: Boolean = false,
    val showCreateAccountForm: Boolean = false,
    val errorMessage: String? = null
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val accountRepository: AccountRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    init {
        loadAccounts()
    }

    fun loadAccounts() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingAccounts = true, errorMessage = null)
            when (val result = accountRepository.listAccounts()) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        accounts = result.data,
                        isLoadingAccounts = false,
                        // Keep selected account if still valid, otherwise select first
                        selectedAccount = _uiState.value.selectedAccount?.let { selected ->
                            result.data.find { it.id == selected.id }
                        } ?: result.data.firstOrNull()
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

    fun selectAccount(account: Account) {
        _uiState.value = _uiState.value.copy(selectedAccount = account)
    }

    fun showCreateAccountForm() {
        _uiState.value = _uiState.value.copy(showCreateAccountForm = true)
    }

    fun hideCreateAccountForm() {
        _uiState.value = _uiState.value.copy(showCreateAccountForm = false)
    }

    fun createAccount(name: String, email: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isCreatingAccount = true, errorMessage = null)
            when (val result = accountRepository.createAccount(name, email)) {
                is Result.Success -> {
                    _uiState.value = _uiState.value.copy(
                        isCreatingAccount = false,
                        showCreateAccountForm = false
                    )
                    // Reload accounts and select the new one
                    loadAccounts()
                    _uiState.value = _uiState.value.copy(selectedAccount = result.data)
                }
                is Result.Error -> {
                    _uiState.value = _uiState.value.copy(
                        isCreatingAccount = false,
                        errorMessage = result.message
                    )
                }
            }
        }
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(errorMessage = null)
    }
}
