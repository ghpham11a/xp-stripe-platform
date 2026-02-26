package com.example.stripedemo.features.accountdetail.components

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.stripedemo.data.models.Account

@Composable
fun AccountCard(
    account: Account,
    isLoading: Boolean,
    onDelete: () -> Unit,
    onUpgradeToRecipient: () -> Unit,
    onStartOnboarding: () -> Unit,
    modifier: Modifier = Modifier
) {
    var showDeleteDialog by remember { mutableStateOf(false) }

    Card(
        modifier = modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Account Details",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )

                IconButton(
                    onClick = { showDeleteDialog = true },
                    enabled = !isLoading
                ) {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = "Delete Account",
                        tint = MaterialTheme.colorScheme.error
                    )
                }
            }

            // Status badges
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                if (account.isCustomer) {
                    SuggestionChip(
                        onClick = {},
                        label = { Text("Customer") }
                    )
                }
                if (account.isRecipient) {
                    SuggestionChip(
                        onClick = {},
                        label = { Text("Recipient") },
                        colors = SuggestionChipDefaults.suggestionChipColors(
                            containerColor = MaterialTheme.colorScheme.primaryContainer
                        )
                    )
                }
                if (account.isOnboarding == true) {
                    SuggestionChip(
                        onClick = {},
                        label = { Text("Onboarding") },
                        colors = SuggestionChipDefaults.suggestionChipColors(
                            containerColor = MaterialTheme.colorScheme.tertiaryContainer
                        )
                    )
                }
            }

            HorizontalDivider()

            // Account info
            AccountInfoRow("Email", account.email ?: "N/A")
            AccountInfoRow("Display Name", account.displayName ?: "N/A")
            AccountInfoRow("Platform ID", account.id)
            AccountInfoRow("Stripe Account ID", account.stripeAccountId)
            account.stripeCustomerId?.let {
                AccountInfoRow("Stripe Customer ID", it)
            }
            AccountInfoRow("Created", account.created)

            // Actions
            if (!account.isRecipient) {
                HorizontalDivider()
                Button(
                    onClick = onUpgradeToRecipient,
                    enabled = !isLoading,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            color = MaterialTheme.colorScheme.onPrimary,
                            strokeWidth = 2.dp
                        )
                    } else {
                        Text("Upgrade to Recipient")
                    }
                }
            }

            if (account.isRecipient && account.isOnboarding == true) {
                HorizontalDivider()
                OutlinedButton(
                    onClick = onStartOnboarding,
                    enabled = !isLoading,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Complete Onboarding")
                }
            }
        }
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete Account") },
            text = { Text("Are you sure you want to delete this account? This action cannot be undone.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDeleteDialog = false
                        onDelete()
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("Delete")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun AccountInfoRow(
    label: String,
    value: String,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium
        )
    }
}
