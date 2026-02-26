package com.example.stripedemo.features.home

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.AccountBox
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.stripedemo.features.home.components.AccountSelector
import com.example.stripedemo.features.home.components.CreateAccountForm

@Composable
fun HomeScreen(
    viewModel: HomeViewModel = hiltViewModel(),
    onNavigateToAccountDetail: (String) -> Unit = {},
    onNavigateToPaymentMethods: (String) -> Unit = {},
    onNavigateToBankAccounts: (String) -> Unit = {}
) {
    val uiState by viewModel.uiState.collectAsState()

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        contentPadding = PaddingValues(vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Text(
                text = "Stripe Demo",
                style = MaterialTheme.typography.headlineMedium
            )
        }

        item {
            if (uiState.isLoadingAccounts && uiState.accounts.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            } else {
                AccountSelector(
                    accounts = uiState.accounts,
                    selectedAccount = uiState.selectedAccount,
                    onAccountSelected = { viewModel.selectAccount(it) },
                    onCreateNewAccount = { viewModel.showCreateAccountForm() },
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }

        if (uiState.showCreateAccountForm) {
            item {
                CreateAccountForm(
                    isLoading = uiState.isCreatingAccount,
                    onCreateAccount = { name, email ->
                        viewModel.createAccount(name, email)
                    },
                    onCancel = { viewModel.hideCreateAccountForm() }
                )
            }
        }

        uiState.errorMessage?.let { error ->
            item {
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    ),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = error,
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            modifier = Modifier.weight(1f)
                        )
                        TextButton(onClick = { viewModel.clearError() }) {
                            Text("Dismiss")
                        }
                    }
                }
            }
        }

        uiState.selectedAccount?.let { account ->
            item {
                NavigationCard(
                    title = "Account Details",
                    description = "View and manage account information",
                    icon = Icons.Default.Person,
                    onClick = { onNavigateToAccountDetail(account.id) }
                )
            }

            item {
                NavigationCard(
                    title = "Payment Methods",
                    description = "Manage saved cards and payment options",
                    icon = Icons.Default.Add,
                    onClick = { onNavigateToPaymentMethods(account.id) }
                )
            }

            item {
                NavigationCard(
                    title = "Bank Accounts",
                    description = "Manage linked bank accounts for payouts",
                    icon = Icons.Default.AccountBox,
                    onClick = { onNavigateToBankAccounts(account.id) }
                )
            }
        }
    }
}

@Composable
private fun NavigationCard(
    title: String,
    description: String,
    icon: ImageVector,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(40.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium
                )
                Text(
                    text = description,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = "Navigate",
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
