package com.example.stripedemo.shared.components

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.example.stripedemo.data.models.Account
import com.example.stripedemo.data.models.PaymentMethod

enum class PaymentMode {
    SAVED_CARD,
    NEW_CARD
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PayUserForm(
    recipients: List<Account>,
    paymentMethods: List<PaymentMethod>,
    isLoading: Boolean,
    onPayWithSavedCard: (recipientId: String, paymentMethodId: String, amount: Int) -> Unit,
    onPayWithNewCard: (recipientId: String, amount: Int, saveCard: Boolean) -> Unit,
    onCancel: () -> Unit,
    modifier: Modifier = Modifier
) {
    var selectedRecipient by remember { mutableStateOf<Account?>(null) }
    var selectedPaymentMethod by remember { mutableStateOf<PaymentMethod?>(null) }
    var amountText by remember { mutableStateOf("") }
    var paymentMode by remember { mutableStateOf(PaymentMode.SAVED_CARD) }
    var saveNewCard by remember { mutableStateOf(false) }
    var recipientExpanded by remember { mutableStateOf(false) }
    var paymentMethodExpanded by remember { mutableStateOf(false) }

    val amount = amountText.toDoubleOrNull()?.times(100)?.toInt() ?: 0
    val isValid = selectedRecipient != null && amount >= 50 &&
            (paymentMode == PaymentMode.NEW_CARD || selectedPaymentMethod != null)

    Card(
        modifier = modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Pay User",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )

            Text(
                text = "Send money to another user (10% platform fee applies)",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            // Recipient selector
            ExposedDropdownMenuBox(
                expanded = recipientExpanded,
                onExpandedChange = { recipientExpanded = it }
            ) {
                OutlinedTextField(
                    value = selectedRecipient?.let { "${it.displayName ?: it.email}" } ?: "Select recipient",
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Recipient") },
                    trailingIcon = {
                        Icon(Icons.Default.ArrowDropDown, "Dropdown")
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor()
                )

                ExposedDropdownMenu(
                    expanded = recipientExpanded,
                    onDismissRequest = { recipientExpanded = false }
                ) {
                    if (recipients.isEmpty()) {
                        DropdownMenuItem(
                            text = { Text("No recipients available") },
                            onClick = { recipientExpanded = false },
                            enabled = false
                        )
                    } else {
                        recipients.forEach { recipient ->
                            DropdownMenuItem(
                                text = {
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.SpaceBetween,
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Text(recipient.displayName ?: recipient.email ?: "Unknown")
                                        if (selectedRecipient?.id == recipient.id) {
                                            Icon(
                                                Icons.Default.Check,
                                                "Selected",
                                                tint = MaterialTheme.colorScheme.primary
                                            )
                                        }
                                    }
                                },
                                onClick = {
                                    selectedRecipient = recipient
                                    recipientExpanded = false
                                }
                            )
                        }
                    }
                }
            }

            // Amount input
            OutlinedTextField(
                value = amountText,
                onValueChange = {
                    if (it.isEmpty() || it.matches(Regex("^\\d*\\.?\\d{0,2}$"))) {
                        amountText = it
                    }
                },
                label = { Text("Amount (USD)") },
                prefix = { Text("$") },
                enabled = !isLoading,
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                supportingText = { Text("Minimum $0.50") },
                isError = amountText.isNotEmpty() && amount < 50
            )

            // Payment mode toggle
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                FilterChip(
                    selected = paymentMode == PaymentMode.SAVED_CARD,
                    onClick = { paymentMode = PaymentMode.SAVED_CARD },
                    label = { Text("Saved Card") },
                    modifier = Modifier.weight(1f)
                )
                FilterChip(
                    selected = paymentMode == PaymentMode.NEW_CARD,
                    onClick = { paymentMode = PaymentMode.NEW_CARD },
                    label = { Text("New Card") },
                    modifier = Modifier.weight(1f)
                )
            }

            if (paymentMode == PaymentMode.SAVED_CARD) {
                // Payment method selector
                ExposedDropdownMenuBox(
                    expanded = paymentMethodExpanded,
                    onExpandedChange = { paymentMethodExpanded = it }
                ) {
                    OutlinedTextField(
                        value = selectedPaymentMethod?.let { pm ->
                            "${pm.card?.brand?.replaceFirstChar { it.uppercase() }} •••• ${pm.card?.last4}"
                        } ?: "Select payment method",
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Payment Method") },
                        trailingIcon = {
                            Icon(Icons.Default.ArrowDropDown, "Dropdown")
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )

                    ExposedDropdownMenu(
                        expanded = paymentMethodExpanded,
                        onDismissRequest = { paymentMethodExpanded = false }
                    ) {
                        if (paymentMethods.isEmpty()) {
                            DropdownMenuItem(
                                text = { Text("No saved cards") },
                                onClick = { paymentMethodExpanded = false },
                                enabled = false
                            )
                        } else {
                            paymentMethods.forEach { pm ->
                                DropdownMenuItem(
                                    text = {
                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.SpaceBetween,
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Text("${pm.card?.brand?.replaceFirstChar { it.uppercase() }} •••• ${pm.card?.last4}")
                                            if (selectedPaymentMethod?.id == pm.id) {
                                                Icon(
                                                    Icons.Default.Check,
                                                    "Selected",
                                                    tint = MaterialTheme.colorScheme.primary
                                                )
                                            }
                                        }
                                    },
                                    onClick = {
                                        selectedPaymentMethod = pm
                                        paymentMethodExpanded = false
                                    }
                                )
                            }
                        }
                    }
                }
            } else {
                // Save card option
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Checkbox(
                        checked = saveNewCard,
                        onCheckedChange = { saveNewCard = it },
                        enabled = !isLoading
                    )
                    Text(
                        text = "Save card for future payments",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }

            // Action buttons
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
                    onClick = {
                        selectedRecipient?.let { recipient ->
                            if (paymentMode == PaymentMode.SAVED_CARD) {
                                selectedPaymentMethod?.let { pm ->
                                    onPayWithSavedCard(recipient.id, pm.id, amount)
                                }
                            } else {
                                onPayWithNewCard(recipient.id, amount, saveNewCard)
                            }
                        }
                    },
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
                        Text("Pay")
                    }
                }
            }
        }
    }
}