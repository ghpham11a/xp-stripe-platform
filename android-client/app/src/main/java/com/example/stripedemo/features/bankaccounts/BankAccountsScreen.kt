package com.example.stripedemo.features.bankaccounts

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.stripedemo.shared.components.BankAccountForm
import com.example.stripedemo.shared.components.BankAccountList
import kotlinx.coroutines.delay

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BankAccountsScreen(
    accountId: String,
    onNavigateBack: () -> Unit,
    viewModel: BankAccountsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // Toast state
    var toastMessage by remember { mutableStateOf<String?>(null) }
    var toastIsError by remember { mutableStateOf(false) }

    // Handle error toast
    LaunchedEffect(uiState.errorMessage) {
        uiState.errorMessage?.let { error ->
            toastMessage = error
            toastIsError = true
            viewModel.clearError()
        }
    }

    // Handle success toast
    LaunchedEffect(uiState.successMessage) {
        uiState.successMessage?.let { message ->
            toastMessage = message
            toastIsError = false
            viewModel.clearSuccessMessage()
        }
    }

    // Auto-dismiss toast
    LaunchedEffect(toastMessage) {
        if (toastMessage != null) {
            delay(3000)
            toastMessage = null
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Bank Accounts") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                }
            )
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            PullToRefreshBox(
                isRefreshing = uiState.isLoadingAccounts,
                onRefresh = { viewModel.loadExternalAccounts() },
                modifier = Modifier.fillMaxSize()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // Test bank info banner
                    TestBankBanner()

                    // Check if account is a recipient
                    val isRecipient = uiState.account?.isRecipient == true

                    if (!isRecipient) {
                        // Not a recipient - show upgrade message
                        NotRecipientMessage()
                    } else if (uiState.showBankAccountForm) {
                        BankAccountForm(
                            isLoading = uiState.isLoading,
                            onSubmit = { holderName, routing, accountNum ->
                                viewModel.createBankAccount(holderName, routing, accountNum)
                            },
                            onCancel = { viewModel.hideBankAccountForm() }
                        )
                    } else {
                        BankAccountList(
                            externalAccounts = uiState.externalAccounts,
                            isLoading = uiState.isLoading,
                            onAddBankAccount = { viewModel.showBankAccountForm() },
                            onSetDefault = { eaId -> viewModel.setDefaultExternalAccount(eaId) },
                            onDelete = { eaId -> viewModel.deleteExternalAccount(eaId) }
                        )
                    }
                }
            }

            // Toast overlay
            AnimatedVisibility(
                visible = toastMessage != null,
                enter = slideInVertically(initialOffsetY = { it }) + fadeIn(),
                exit = slideOutVertically(targetOffsetY = { it }) + fadeOut(),
                modifier = Modifier.align(Alignment.BottomCenter)
            ) {
                toastMessage?.let { message ->
                    Surface(
                        shape = MaterialTheme.shapes.medium,
                        color = if (toastIsError) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary,
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Text(
                            text = message,
                            color = if (toastIsError) MaterialTheme.colorScheme.onError else MaterialTheme.colorScheme.onPrimary,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun TestBankBanner() {
    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
        ),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(12.dp)
        ) {
            Text(
                text = "Test Bank: Routing 110000000",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.primary
            )
            Text(
                text = "Account 000123456789",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
}

@Composable
private fun NotRecipientMessage() {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(40.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "Recipient Account Required",
                style = MaterialTheme.typography.titleMedium
            )
            Text(
                text = "Upgrade this account to a recipient to add bank accounts for payouts.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
        }
    }
}
