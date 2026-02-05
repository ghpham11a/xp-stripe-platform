//
//  AccountView+ViewModel.swift
//  StripeApplication
//

import Foundation
import Observation

extension AccountView {
    @Observable
    class ViewModel {
        var account: Account
        var isLoading: Bool = false
        var error: String? = nil
        var successMessage: String? = nil
        var onboardingUrl: String? = nil
        var wasDeleted: Bool = false

        private let accountRepository = AccountRepository.shared

        init(account: Account) {
            self.account = account
        }

        func loadAccount() async {
            do {
                account = try await accountRepository.get(accountId: account.id)
            } catch {
                self.error = error.localizedDescription
            }
        }

        func deleteAccount() async {
            isLoading = true
            error = nil
            do {
                try await accountRepository.delete(accountId: account.id)
                successMessage = "Account deleted successfully"
                wasDeleted = true
                isLoading = false
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }

        func upgradeToRecipient() async {
            isLoading = true
            error = nil
            do {
                _ = try await accountRepository.upgradeToRecipient(accountId: account.id)
                successMessage = "Account upgraded to recipient"
                isLoading = false
                await loadAccount()
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }

        func createOnboardingLink() async {
            isLoading = true
            error = nil
            do {
                let response = try await accountRepository.createOnboardingLink(
                    accountId: account.id,
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

        func clearError() {
            error = nil
        }

        func clearSuccessMessage() {
            successMessage = nil
        }
    }
}
