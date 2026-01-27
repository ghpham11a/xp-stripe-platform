import Foundation
import SwiftUI
import Observation

@Observable
class MainViewModel {
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

    private let api = APIClient.shared

    init() {
        Task { await loadAccounts() }
    }

    // MARK: - Accounts

    func loadAccounts() async {
        isLoading = true
        error = nil
        do {
            accounts = try await api.listAccounts()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func createAccount(name: String, email: String) async {
        isLoading = true
        error = nil
        do {
            let account = try await api.createAccount(name: name, email: email)
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
            let account = try await api.getAccount(accountId: accountId)
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
            try await api.deleteAccount(accountId: accountId)
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
            _ = try await api.upgradeToRecipient(accountId: accountId)
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
            let response = try await api.createOnboardingLink(
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
            paymentMethods = try await api.listPaymentMethods(accountId: accountId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createSetupIntent(accountId: String, customerId: String? = nil) async {
        isLoading = true
        error = nil
        do {
            let response = try await api.createSetupIntent(accountId: accountId, customerId: customerId)
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
            try await api.deletePaymentMethod(accountId: accountId, paymentMethodId: paymentMethodId)
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
            externalAccounts = try await api.listExternalAccounts(accountId: accountId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createExternalAccount(accountId: String, token: String) async {
        isLoading = true
        error = nil
        do {
            _ = try await api.createExternalAccount(accountId: accountId, token: token)
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
            try await api.deleteExternalAccount(accountId: accountId, externalAccountId: externalAccountId)
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
            _ = try await api.setDefaultExternalAccount(accountId: accountId, externalAccountId: externalAccountId)
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
            let tokenId = try await api.createBankAccountToken(
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
            _ = try await api.payUser(
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
            let response = try await api.createPaymentIntent(
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
