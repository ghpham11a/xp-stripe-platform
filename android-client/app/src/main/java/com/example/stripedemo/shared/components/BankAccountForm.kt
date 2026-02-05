package com.example.stripedemo.shared.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp

@Composable
fun BankAccountForm(
    isLoading: Boolean,
    onSubmit: (accountHolderName: String, routingNumber: String, accountNumber: String) -> Unit,
    onCancel: () -> Unit,
    modifier: Modifier = Modifier
) {
    var accountHolderName by remember { mutableStateOf("") }
    var routingNumber by remember { mutableStateOf("") }
    var accountNumber by remember { mutableStateOf("") }
    var confirmAccountNumber by remember { mutableStateOf("") }

    val isValid = accountHolderName.isNotBlank() &&
            routingNumber.length == 9 &&
            accountNumber.isNotBlank() &&
            accountNumber == confirmAccountNumber

    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "Add Bank Account",
                style = MaterialTheme.typography.titleMedium
            )

            // Test data info
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                )
            ) {
                Column(
                    modifier = Modifier.padding(12.dp)
                ) {
                    Text(
                        text = "Test Data:",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = "Routing: 110000000",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = "Account: 000123456789",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }

            OutlinedTextField(
                value = accountHolderName,
                onValueChange = { accountHolderName = it },
                label = { Text("Account Holder Name") },
                enabled = !isLoading,
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            OutlinedTextField(
                value = routingNumber,
                onValueChange = { if (it.length <= 9 && it.all { c -> c.isDigit() }) routingNumber = it },
                label = { Text("Routing Number") },
                enabled = !isLoading,
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                supportingText = {
                    Text("${routingNumber.length}/9 digits")
                },
                isError = routingNumber.isNotEmpty() && routingNumber.length != 9
            )

            OutlinedTextField(
                value = accountNumber,
                onValueChange = { if (it.all { c -> c.isDigit() }) accountNumber = it },
                label = { Text("Account Number") },
                enabled = !isLoading,
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
            )

            OutlinedTextField(
                value = confirmAccountNumber,
                onValueChange = { if (it.all { c -> c.isDigit() }) confirmAccountNumber = it },
                label = { Text("Confirm Account Number") },
                enabled = !isLoading,
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                isError = confirmAccountNumber.isNotEmpty() && accountNumber != confirmAccountNumber,
                supportingText = if (confirmAccountNumber.isNotEmpty() && accountNumber != confirmAccountNumber) {
                    { Text("Account numbers don't match") }
                } else null
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = onCancel,
                    enabled = !isLoading,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Cancel")
                }

                Button(
                    onClick = { onSubmit(accountHolderName, routingNumber, accountNumber) },
                    enabled = !isLoading && isValid,
                    modifier = Modifier.weight(1f)
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            color = MaterialTheme.colorScheme.onPrimary,
                            strokeWidth = 2.dp
                        )
                    } else {
                        Text("Add Bank")
                    }
                }
            }
        }
    }
}