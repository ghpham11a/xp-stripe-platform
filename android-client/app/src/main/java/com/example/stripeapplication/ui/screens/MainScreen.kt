package com.example.stripeapplication.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.stripeapplication.ui.components.*
import com.example.stripeapplication.viewmodel.MainViewModel
import com.stripe.android.PaymentConfiguration
import com.stripe.android.model.ConfirmPaymentIntentParams
import com.stripe.android.model.ConfirmSetupIntentParams
import com.stripe.android.payments.paymentlauncher.PaymentLauncher
import com.stripe.android.payments.paymentlauncher.PaymentResult
import com.example.stripeapplication.BuildConfig

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(
    viewModel: MainViewModel = viewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    val scrollState = rememberScrollState()
    val snackbarHostState = remember { SnackbarHostState() }

    var showCreateAccountForm by remember { mutableStateOf(false) }
    var showAddCardSheet by remember { mutableStateOf(false) }
    var showBankAccountForm by remember { mutableStateOf(false) }
    var showPayUserForm by remember { mutableStateOf(false) }

    // Store pending payment info for new card flow
    var pendingPaymentRecipientId by remember { mutableStateOf<String?>(null) }
    var pendingSaveCard by remember { mutableStateOf(false) }

    // Initialize Stripe
    LaunchedEffect(Unit) {
        PaymentConfiguration.init(context, BuildConfig.STRIPE_PUBLISHABLE_KEY)
    }

    // Payment launcher for SetupIntent
    val setupPaymentLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { /* handled by PaymentLauncher callbacks */ }

    val paymentLauncher = PaymentLauncher.rememberLauncher(
        publishableKey = BuildConfig.STRIPE_PUBLISHABLE_KEY,
        stripeAccountId = null
    ) { result ->
        when (result) {
            is PaymentResult.Completed -> {
                uiState.selectedAccount?.let { account ->
                    if (uiState.setupIntentClientSecret != null) {
                        viewModel.onSetupIntentConfirmed(account.id)
                    } else if (uiState.paymentIntentClientSecret != null) {
                        viewModel.onPaymentIntentConfirmed(account.id)
                    }
                }
                showAddCardSheet = false
                showPayUserForm = false
            }
            is PaymentResult.Canceled -> {
                viewModel.clearSetupIntent()
                viewModel.clearPaymentIntent()
            }
            is PaymentResult.Failed -> {
                viewModel.clearSetupIntent()
                viewModel.clearPaymentIntent()
            }
        }
    }

    // Handle SetupIntent confirmation
    LaunchedEffect(uiState.setupIntentClientSecret) {
        uiState.setupIntentClientSecret?.let { clientSecret ->
            val confirmParams = ConfirmSetupIntentParams.create(
                clientSecret = clientSecret,
                paymentMethodType = com.stripe.android.model.PaymentMethod.Type.Card
            )
            paymentLauncher.confirm(confirmParams)
        }
    }

    // Handle PaymentIntent confirmation
    LaunchedEffect(uiState.paymentIntentClientSecret) {
        uiState.paymentIntentClientSecret?.let { clientSecret ->
            val confirmParams = ConfirmPaymentIntentParams.create(
                clientSecret = clientSecret,
                paymentMethodType = com.stripe.android.model.PaymentMethod.Type.Card
            )
            paymentLauncher.confirm(confirmParams)
        }
    }

    // Handle onboarding URL
    LaunchedEffect(uiState.onboardingUrl) {
        uiState.onboardingUrl?.let { url ->
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            context.startActivity(intent)
            viewModel.clearOnboardingUrl()
        }
    }

    // Show error/success messages
    LaunchedEffect(uiState.error) {
        uiState.error?.let { error ->
            snackbarHostState.showSnackbar(
                message = error,
                duration = SnackbarDuration.Short
            )
            viewModel.clearError()
        }
    }

    LaunchedEffect(uiState.successMessage) {
        uiState.successMessage?.let { message ->
            snackbarHostState.showSnackbar(
                message = message,
                duration = SnackbarDuration.Short
            )
            viewModel.clearSuccessMessage()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Stripe Connect Demo",
                        fontWeight = FontWeight.Bold
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(scrollState)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Test card info
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f)
                )
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

            // Account Selector
            if (showCreateAccountForm) {
                CreateAccountForm(
                    isLoading = uiState.isLoading,
                    onCreateAccount = { name, email ->
                        viewModel.createAccount(name, email)
                        showCreateAccountForm = false
                    },
                    onCancel = { showCreateAccountForm = false }
                )
            } else {
                AccountSelector(
                    accounts = uiState.accounts,
                    selectedAccount = uiState.selectedAccount,
                    onAccountSelected = { viewModel.selectAccount(it) },
                    onCreateNewAccount = { showCreateAccountForm = true }
                )
            }

            // Selected Account Details
            uiState.selectedAccount?.let { account ->
                AccountCard(
                    account = account,
                    isLoading = uiState.isLoading,
                    onDelete = { viewModel.deleteAccount(account.id) },
                    onUpgradeToRecipient = { viewModel.upgradeToRecipient(account.id) },
                    onStartOnboarding = {
                        viewModel.createOnboardingLink(
                            account.id,
                            refreshUrl = "https://example.com/refresh",
                            returnUrl = "https://example.com/return"
                        )
                    }
                )

                // Payment Methods
                if (showAddCardSheet) {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surfaceVariant
                        )
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
                                    onClick = { showAddCardSheet = false },
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Text("Cancel")
                                }
                                Button(
                                    onClick = {
                                        viewModel.createSetupIntent(account.id, account.stripeCustomerId)
                                    },
                                    enabled = !uiState.isLoading,
                                    modifier = Modifier.weight(1f)
                                ) {
                                    if (uiState.isLoading) {
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
                } else {
                    PaymentMethodList(
                        paymentMethods = uiState.paymentMethods,
                        isLoading = uiState.isLoading,
                        onAddCard = { showAddCardSheet = true },
                        onDeletePaymentMethod = { pmId ->
                            viewModel.deletePaymentMethod(account.id, pmId)
                        }
                    )
                }

                // Bank Accounts (only for recipients)
                if (account.isRecipient) {
                    if (showBankAccountForm) {
                        BankAccountFormWithStripe(
                            isLoading = uiState.isLoading,
                            onTokenCreated = { token ->
                                viewModel.createExternalAccount(account.id, token)
                                showBankAccountForm = false
                            },
                            onCancel = { showBankAccountForm = false }
                        )
                    } else {
                        BankAccountList(
                            externalAccounts = uiState.externalAccounts,
                            isLoading = uiState.isLoading,
                            onAddBankAccount = { showBankAccountForm = true },
                            onSetDefault = { eaId ->
                                viewModel.setDefaultExternalAccount(account.id, eaId)
                            },
                            onDelete = { eaId ->
                                viewModel.deleteExternalAccount(account.id, eaId)
                            }
                        )
                    }
                }

                // Pay User (only if we have payment methods and there are recipients)
                val recipients = uiState.accounts.filter { it.isRecipient && it.id != account.id }
                if (uiState.paymentMethods.isNotEmpty() || recipients.isNotEmpty()) {
                    if (showPayUserForm) {
                        PayUserForm(
                            recipients = recipients,
                            paymentMethods = uiState.paymentMethods,
                            isLoading = uiState.isLoading,
                            onPayWithSavedCard = { recipientId, pmId, amount ->
                                viewModel.payUser(account.id, recipientId, pmId, amount)
                                showPayUserForm = false
                            },
                            onPayWithNewCard = { recipientId, amount, saveCard ->
                                pendingPaymentRecipientId = recipientId
                                pendingSaveCard = saveCard
                                viewModel.createPaymentIntent(account.id, recipientId, amount, saveCard)
                            },
                            onCancel = { showPayUserForm = false }
                        )
                    } else {
                        Button(
                            onClick = { showPayUserForm = true },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("Pay Another User")
                        }
                    }
                }
            }

            // Loading indicator
            if (uiState.isLoading && uiState.selectedAccount == null) {
                Box(
                    modifier = Modifier.fillMaxWidth(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }
        }
    }
}

@Composable
private fun BankAccountFormWithStripe(
    isLoading: Boolean,
    onTokenCreated: (String) -> Unit,
    onCancel: () -> Unit
) {
    val context = LocalContext.current
    var isCreatingToken by remember { mutableStateOf(false) }

    BankAccountForm(
        isLoading = isLoading || isCreatingToken,
        onSubmit = { accountHolderName, routingNumber, accountNumber ->
            isCreatingToken = true
            // Create bank account token using Stripe
            val stripe = com.stripe.android.Stripe(
                context,
                BuildConfig.STRIPE_PUBLISHABLE_KEY
            )

            val bankAccountParams = com.stripe.android.model.BankAccountTokenParams(
                country = "US",
                currency = "usd",
                accountHolderName = accountHolderName,
                accountHolderType = com.stripe.android.model.BankAccountTokenParams.Type.Individual,
                routingNumber = routingNumber,
                accountNumber = accountNumber
            )

            stripe.createBankAccountToken(
                bankAccountParams,
                callback = object : com.stripe.android.ApiResultCallback<com.stripe.android.model.Token> {
                    override fun onSuccess(result: com.stripe.android.model.Token) {
                        isCreatingToken = false
                        onTokenCreated(result.id)
                    }

                    override fun onError(e: Exception) {
                        isCreatingToken = false
                        // Error handling is done via ViewModel
                    }
                }
            )
        },
        onCancel = onCancel
    )
}
