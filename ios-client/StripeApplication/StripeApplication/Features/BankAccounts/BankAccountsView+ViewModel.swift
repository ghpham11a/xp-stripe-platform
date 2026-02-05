//
//  BankAccountsView+ViewModel.swift
//  StripeApplication
//

import Foundation
import Observation

extension BankAccountsView {
    @Observable
    class ViewModel {
        let accountId: String
        var isRecipient: Bool

        var externalAccounts: [ExternalAccount] = []
        var isLoading: Bool = false
        var error: String? = nil
        var successMessage: String? = nil

        private let externalAccountRepository = ExternalAccountRepository.shared

        init(accountId: String, isRecipient: Bool) {
            self.accountId = accountId
            self.isRecipient = isRecipient
            Task { await loadExternalAccounts() }
        }

        func loadExternalAccounts() async {
            do {
                externalAccounts = try await externalAccountRepository.list(accountId: accountId)
            } catch {
                self.error = error.localizedDescription
            }
        }

        func createExternalAccount(token: String) async {
            isLoading = true
            error = nil
            do {
                _ = try await externalAccountRepository.create(accountId: accountId, token: token)
                successMessage = "Bank account added successfully"
                isLoading = false
                await loadExternalAccounts()
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }

        func deleteExternalAccount(externalAccountId: String) async {
            isLoading = true
            error = nil
            do {
                try await externalAccountRepository.delete(accountId: accountId, externalAccountId: externalAccountId)
                successMessage = "Bank account removed"
                isLoading = false
                await loadExternalAccounts()
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }

        func setDefaultExternalAccount(externalAccountId: String) async {
            isLoading = true
            error = nil
            do {
                _ = try await externalAccountRepository.setDefault(accountId: accountId, externalAccountId: externalAccountId)
                successMessage = "Default bank account updated"
                isLoading = false
                await loadExternalAccounts()
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }

        func createBankAccountToken(
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
                await createExternalAccount(token: tokenId)
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }

        func clearError() {
            error = nil
        }

        func clearSuccessMessage() {
            successMessage = nil
        }
    }
}
