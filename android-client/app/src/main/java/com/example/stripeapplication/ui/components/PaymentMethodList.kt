package com.example.stripeapplication.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.stripeapplication.data.models.PaymentMethod

@Composable
fun PaymentMethodList(
    paymentMethods: List<PaymentMethod>,
    isLoading: Boolean,
    onAddCard: () -> Unit,
    onDeletePaymentMethod: (String) -> Unit,
    modifier: Modifier = Modifier
) {
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
                    text = "Payment Methods",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )

                IconButton(
                    onClick = onAddCard,
                    enabled = !isLoading
                ) {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = "Add Card",
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
            }

            if (paymentMethods.isEmpty()) {
                Text(
                    text = "No payment methods saved",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            } else {
                paymentMethods.forEach { pm ->
                    PaymentMethodItem(
                        paymentMethod = pm,
                        isLoading = isLoading,
                        onDelete = { onDeletePaymentMethod(pm.id) }
                    )
                }
            }
        }
    }
}

@Composable
private fun PaymentMethodItem(
    paymentMethod: PaymentMethod,
    isLoading: Boolean,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    var showDeleteDialog by remember { mutableStateOf(false) }

    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Card brand icon placeholder
                Text(
                    text = getCardBrandEmoji(paymentMethod.card?.brand ?: ""),
                    style = MaterialTheme.typography.headlineSmall
                )

                Column {
                    Text(
                        text = "${paymentMethod.card?.brand?.replaceFirstChar { it.uppercase() } ?: "Card"} •••• ${paymentMethod.card?.last4 ?: "****"}",
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Medium
                    )
                    Text(
                        text = "Expires ${paymentMethod.card?.expMonth}/${paymentMethod.card?.expYear}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            IconButton(
                onClick = { showDeleteDialog = true },
                enabled = !isLoading
            ) {
                Icon(
                    imageVector = Icons.Default.Delete,
                    contentDescription = "Delete",
                    tint = MaterialTheme.colorScheme.error
                )
            }
        }
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Remove Payment Method") },
            text = { Text("Are you sure you want to remove this card?") },
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
                    Text("Remove")
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

private fun getCardBrandEmoji(brand: String): String {
    return when (brand.lowercase()) {
        "visa" -> "💳"
        "mastercard" -> "💳"
        "amex" -> "💳"
        "discover" -> "💳"
        else -> "💳"
    }
}
