package com.example.stripedemo.features.accountdetail

import android.content.Intent
import android.net.Uri
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.stripedemo.shared.components.AccountCard
import kotlinx.coroutines.delay

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AccountDetailScreen(
    accountId: String,
    onNavigateBack: () -> Unit,
    viewModel: AccountDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current

    // Toast state
    var toastMessage by remember { mutableStateOf<String?>(null) }
    var toastIsError by remember { mutableStateOf(false) }

    // Handle account deletion - navigate back
    LaunchedEffect(uiState.wasDeleted) {
        if (uiState.wasDeleted) {
            onNavigateBack()
        }
    }

    // Handle onboarding URL - open in browser
    LaunchedEffect(uiState.onboardingUrl) {
        uiState.onboardingUrl?.let { url ->
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            context.startActivity(intent)
            viewModel.clearOnboardingUrl()
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
                title = {
                    Text(uiState.account?.displayName ?: uiState.account?.email ?: "Account")
                },
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
                isRefreshing = uiState.isLoading,
                onRefresh = { viewModel.loadAccount() },
                modifier = Modifier.fillMaxSize()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    uiState.account?.let { account ->
                        AccountCard(
                            account = account,
                            isLoading = uiState.isLoading,
                            onDelete = { viewModel.deleteAccount() },
                            onUpgradeToRecipient = { viewModel.upgradeToRecipient() },
                            onStartOnboarding = { viewModel.createOnboardingLink() }
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
