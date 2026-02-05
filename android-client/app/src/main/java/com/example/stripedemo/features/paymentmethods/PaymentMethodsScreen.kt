package com.example.stripedemo.features.paymentmethods

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
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.stripedemo.shared.components.PaymentMethodList
import com.stripe.android.paymentsheet.PaymentSheet
import com.stripe.android.paymentsheet.PaymentSheetResult
import com.stripe.android.paymentsheet.rememberPaymentSheet
import kotlinx.coroutines.delay

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PaymentMethodsScreen(
    accountId: String,
    onNavigateBack: () -> Unit,
    viewModel: PaymentMethodsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // Toast state
    var toastMessage by remember { mutableStateOf<String?>(null) }
    var toastIsError by remember { mutableStateOf(false) }

    // Initialize Stripe PaymentSheet
    val paymentSheet = rememberPaymentSheet { result ->
        when (result) {
            is PaymentSheetResult.Completed -> {
                viewModel.onSetupIntentConfirmed()
            }
            is PaymentSheetResult.Canceled -> {
                viewModel.clearSetupIntent()
            }
            is PaymentSheetResult.Failed -> {
                viewModel.clearSetupIntent()
                toastMessage = result.error.localizedMessage ?: "Payment sheet failed"
                toastIsError = true
            }
        }
    }

    // Handle SetupIntent client secret - present PaymentSheet
    LaunchedEffect(uiState.setupIntentClientSecret) {
        uiState.setupIntentClientSecret?.let { clientSecret ->
            val configuration = PaymentSheet.Configuration(
                merchantDisplayName = "Stripe Connect Demo"
            )
            paymentSheet.presentWithSetupIntent(
                setupIntentClientSecret = clientSecret,
                configuration = configuration
            )
        }
    }

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
                title = { Text("Payment Methods") },
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
                isRefreshing = uiState.isLoadingMethods,
                onRefresh = { viewModel.loadPaymentMethods() },
                modifier = Modifier.fillMaxSize()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // Test card info banner
                    TestCardBanner()

                    // Payment Methods
                    if (uiState.showAddCardSection) {
                        AddCardSection(
                            isLoading = uiState.isLoading,
                            onCancel = { viewModel.hideAddCardSection() },
                            onAddCard = { viewModel.createSetupIntent() }
                        )
                    } else {
                        PaymentMethodList(
                            paymentMethods = uiState.paymentMethods,
                            isLoading = uiState.isLoading,
                            onAddCard = { viewModel.showAddCardSection() },
                            onDeletePaymentMethod = { pmId -> viewModel.deletePaymentMethod(pmId) }
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
private fun TestCardBanner() {
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
                text = "Test Card: 4242 4242 4242 4242",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.primary
            )
            Text(
                text = "Any future expiry, any CVC",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
}

@Composable
private fun AddCardSection(
    isLoading: Boolean,
    onCancel: () -> Unit,
    onAddCard: () -> Unit
) {
    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        ),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "Add Card",
                style = MaterialTheme.typography.titleMedium
            )
            Text(
                text = "Click the button below to add a new card using Stripe's secure payment sheet.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
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
                    onClick = onAddCard,
                    enabled = !isLoading,
                    modifier = Modifier.weight(1f)
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            color = MaterialTheme.colorScheme.onPrimary,
                            strokeWidth = 2.dp
                        )
                    } else {
                        Text("Add Card")
                    }
                }
            }
        }
    }
}
