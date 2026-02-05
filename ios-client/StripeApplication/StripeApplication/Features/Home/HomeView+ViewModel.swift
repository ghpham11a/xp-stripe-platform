//
//  HomeView+ViewModel.swift
//  StripeApplication
//
//  Created by Anthony Pham on 2/4/26.
//
import Foundation
import SwiftUI
import Observation

extension HomeView {
    @Observable
    class ViewModel {
        var accounts: [Account] = []
        var selectedAccount: Account? = nil
        var paymentMethods: [PaymentMethod] = []
        var externalAccounts: [ExternalAccount] = []
        var isLoading: Bool = false
        var error: String? = nil
        var successMessage: String? = nil
        var setupIntentClientSecret: String? = nil
        var paymentIntentClientSecret: String? = nil
        var onboardingUrl: String? = nil

        private let accountRepository = AccountRepository.shared
        private let paymentMethodRepository = PaymentMethodRepository.shared
        private let externalAccountRepository = ExternalAccountRepository.shared
        private let transactionRepository = TransactionRepository.shared

        init() {
            Task { await loadAccounts() }
        }

        // MARK: - Accounts

        func loadAccounts() async {
            isLoading = true
            error = nil
            do {
                accounts = try await accountRepository.list()
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }

        func createAccount(name: String, email: String) async {
            isLoading = true
            error = nil
            do {
                let account = try await accountRepository.create(name: name, email: email)
                selectedAccount = account
                successMessage = "Account created successfully"
                isLoading = false
                await loadAccounts()
                await loadAccountData(accountId: account.id)
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }

        func selectAccount(_ account: Account) {
            selectedAccount = account
            Task { await loadAccountData(accountId: account.id) }
        }

        func loadAccountData(accountId: String) async {
            do {
                let account = try await accountRepository.get(accountId: accountId)
                selectedAccount = account
            } catch {
                self.error = error.localizedDescription
            }
            await loadPaymentMethods(accountId: accountId)
            await loadExternalAccounts(accountId: accountId)
        }

        func deleteAccount(accountId: String) async {
            isLoading = true
            error = nil
            do {
                try await accountRepository.delete(accountId: accountId)
                selectedAccount = nil
                paymentMethods = []
                externalAccounts = []
                successMessage = "Account deleted successfully"
                isLoading = false
                await loadAccounts()
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }

        func upgradeToRecipient(accountId: String) async {
            isLoading = true
            error = nil
            do {
                _ = try await accountRepository.upgradeToRecipient(accountId: accountId)
                successMessage = "Account upgraded to recipient"
                isLoading = false
                await loadAccountData(accountId: accountId)
                await loadAccounts()
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }

        func createOnboardingLink(accountId: String) async {
            isLoading = true
            error = nil
            do {
                let response = try await accountRepository.createOnboardingLink(
                    accountId: accountId,
                    refreshUrl: "https://example.com/refresh",
                    returnUrl: "https://example.com/return"
                )
                onboardingUrl = response.url
                isLoading = false
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }

        func clearOnboardingUrl() {
            onboardingUrl = nil
        }

        // MARK: - Payment Methods

        func loadPaymentMethods(accountId: String) async {
            do {
                paymentMethods = try await paymentMethodRepository.list(accountId: accountId)
            } catch {
                self.error = error.localizedDescription
            }
        }

        func createSetupIntent(accountId: String, customerId: String? = nil) async {
            isLoading = true
            error = nil
            do {
                let response = try await paymentMethodRepository.createSetupIntent(accountId: accountId, customerId: customerId)
                setupIntentClientSecret = response.clientSecret
                isLoading = false
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }

        func clearSetupIntent() {
            setupIntentClientSecret = nil
        }

        func onSetupIntentConfirmed(accountId: String) {
            setupIntentClientSecret = nil
            successMessage = "Card added successfully"
            Task { await loadPaymentMethods(accountId: accountId) }
        }

        func deletePaymentMethod(accountId: String, paymentMethodId: String) async {
            isLoading = true
            error = nil
            do {
                try await paymentMethodRepository.delete(accountId: accountId, paymentMethodId: paymentMethodId)
                successMessage = "Payment method removed"
                isLoading = false
                await loadPaymentMethods(accountId: accountId)
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }

        // MARK: - External Accounts

        func loadExternalAccounts(accountId: String) async {
            do {
                externalAccounts = try await externalAccountRepository.list(accountId: accountId)
            } catch {
                self.error = error.localizedDescription
            }
        }

        func createExternalAccount(accountId: String, token: String) async {
            isLoading = true
            error = nil
            do {
                _ = try await externalAccountRepository.create(accountId: accountId, token: token)
                successMessage = "Bank account added successfully"
                isLoading = false
                await loadExternalAccounts(accountId: accountId)
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }

        func deleteExternalAccount(accountId: String, externalAccountId: String) async {
            isLoading = true
            error = nil
            do {
                try await externalAccountRepository.delete(accountId: accountId, externalAccountId: externalAccountId)
                successMessage = "Bank account removed"
                isLoading = false
                await loadExternalAccounts(accountId: accountId)
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }

        func setDefaultExternalAccount(accountId: String, externalAccountId: String) async {
            isLoading = true
            error = nil
            do {
                _ = try await externalAccountRepository.setDefault(accountId: accountId, externalAccountId: externalAccountId)
                successMessage = "Default bank account updated"
                isLoading = false
                await loadExternalAccounts(accountId: accountId)
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }

        func createBankAccountToken(
            accountId: String,
            accountHolderName: String,
            routingNumber: String,
            accountNumber: String
        ) async {
            isLoading = true
            error = nil
            do {
                let tokenId = try await externalAccountRepository.createBankAccountToken(
                    accountHolderName: accountHolderName,
                    routingNumber: routingNumber,
                    accountNumber: accountNumber
                )
                await createExternalAccount(accountId: accountId, token: tokenId)
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }

        // MARK: - Transactions

        func payUser(accountId: String, recipientAccountId: String, paymentMethodId: String, amount: Int) async {
            isLoading = true
            error = nil
            do {
                _ = try await transactionRepository.payUser(
                    accountId: accountId,
                    recipientAccountId: recipientAccountId,
                    paymentMethodId: paymentMethodId,
                    amount: amount
                )
                successMessage = "Payment of $\(String(format: "%.2f", Double(amount) / 100.0)) sent successfully!"
                isLoading = false
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }

        func createPaymentIntent(accountId: String, recipientAccountId: String, amount: Int, savePaymentMethod: Bool) async {
            isLoading = true
            error = nil
            do {
                let response = try await transactionRepository.createPaymentIntent(
                    accountId: accountId,
                    recipientAccountId: recipientAccountId,
                    amount: amount,
                    savePaymentMethod: savePaymentMethod
                )
                paymentIntentClientSecret = response.clientSecret
                isLoading = false
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }

        func clearPaymentIntent() {
            paymentIntentClientSecret = nil
        }

        func onPaymentIntentConfirmed(accountId: String) {
            paymentIntentClientSecret = nil
            successMessage = "Payment completed successfully!"
            Task { await loadPaymentMethods(accountId: accountId) }
        }

        func clearError() {
            error = nil
        }

        func clearSuccessMessage() {
            successMessage = nil
        }
    }
}
