package com.example.stripedemo.features.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.stripedemo.data.models.Account
import com.example.stripedemo.data.repositories.accounts.AccountRepository
import com.example.stripedemo.core.datastore.AppPreferences
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
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
    private val accountRepository: AccountRepository,
    private val appPreferences: AppPreferences
) : ViewModel() {

    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    private val savedAccountId: StateFlow<String> = appPreferences.selectedAccountId
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = ""
        )

    init {
        loadAccounts()
    }

    fun loadAccounts() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingAccounts = true, errorMessage = null) }
            accountRepository.listAccounts()
                .onSuccess { accounts ->
                    val savedId = savedAccountId.value
                    _uiState.update { state ->
                        val selectedAccount = when {
                            // Try to restore from saved preferences
                            savedId.isNotEmpty() -> accounts.find { it.id == savedId }
                            // Keep current selection if still valid
                            state.selectedAccount != null -> accounts.find { it.id == state.selectedAccount.id }
                            else -> null
                        } ?: accounts.firstOrNull()

                        state.copy(
                            accounts = accounts,
                            isLoadingAccounts = false,
                            selectedAccount = selectedAccount
                        )
                    }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isLoadingAccounts = false, errorMessage = error.message) }
                }
        }
    }

    fun selectAccount(account: Account) {
        _uiState.update { it.copy(selectedAccount = account) }
        viewModelScope.launch {
            appPreferences.setSelectedAccountId(account.id)
        }
    }

    fun showCreateAccountForm() {
        _uiState.update { it.copy(showCreateAccountForm = true) }
    }

    fun hideCreateAccountForm() {
        _uiState.update { it.copy(showCreateAccountForm = false) }
    }

    fun createAccount(name: String, email: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isCreatingAccount = true, errorMessage = null) }
            accountRepository.createAccount(name, email)
                .onSuccess { account ->
                    _uiState.update { it.copy(isCreatingAccount = false, showCreateAccountForm = false) }
                    // Reload accounts and select the new one
                    loadAccounts()
                    selectAccount(account)
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isCreatingAccount = false, errorMessage = error.message) }
                }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(errorMessage = null) }
    }
}
