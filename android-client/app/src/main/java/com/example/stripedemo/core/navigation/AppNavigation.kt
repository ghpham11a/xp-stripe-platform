package com.example.stripedemo.core.navigation

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.stripedemo.features.accountdetail.AccountDetailScreen
import com.example.stripedemo.features.bankaccounts.BankAccountsScreen
import com.example.stripedemo.features.home.HomeScreen
import com.example.stripedemo.features.paymentmethods.PaymentMethodsScreen

object Routes {
    const val HOME = "home"
    const val ACCOUNT_DETAIL = "account_detail/{accountId}"
    const val PAYMENT_METHODS = "payment_methods/{accountId}"
    const val BANK_ACCOUNTS = "bank_accounts/{accountId}"

    fun accountDetail(accountId: String) = "account_detail/$accountId"
    fun paymentMethods(accountId: String) = "payment_methods/$accountId"
    fun bankAccounts(accountId: String) = "bank_accounts/$accountId"
}

@Composable
fun AppNavigation(navController: NavHostController = rememberNavController()) {
    Scaffold(
        modifier = Modifier.fillMaxSize()
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Routes.HOME,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Routes.HOME) {
                HomeScreen(
                    onNavigateToAccountDetail = { accountId ->
                        navController.navigate(Routes.accountDetail(accountId))
                    },
                    onNavigateToPaymentMethods = { accountId ->
                        navController.navigate(Routes.paymentMethods(accountId))
                    },
                    onNavigateToBankAccounts = { accountId ->
                        navController.navigate(Routes.bankAccounts(accountId))
                    }
                )
            }

            composable(
                route = Routes.ACCOUNT_DETAIL,
                arguments = listOf(navArgument("accountId") { type = NavType.StringType })
            ) { backStackEntry ->
                val accountId = backStackEntry.arguments?.getString("accountId") ?: ""
                AccountDetailScreen(
                    accountId = accountId,
                    onNavigateBack = { navController.popBackStack() }
                )
            }

            composable(
                route = Routes.PAYMENT_METHODS,
                arguments = listOf(navArgument("accountId") { type = NavType.StringType })
            ) { backStackEntry ->
                val accountId = backStackEntry.arguments?.getString("accountId") ?: ""
                PaymentMethodsScreen(
                    accountId = accountId,
                    onNavigateBack = { navController.popBackStack() }
                )
            }

            composable(
                route = Routes.BANK_ACCOUNTS,
                arguments = listOf(navArgument("accountId") { type = NavType.StringType })
            ) { backStackEntry ->
                val accountId = backStackEntry.arguments?.getString("accountId") ?: ""
                BankAccountsScreen(
                    accountId = accountId,
                    onNavigateBack = { navController.popBackStack() }
                )
            }
        }
    }
}
