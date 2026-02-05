//
//  HomeView+ViewModel.swift
//  StripeApplication
//
//  Created by Anthony Pham on 2/4/26.
//
import Foundation
import Observation

extension HomeView {
    @Observable
    class ViewModel {
        var accounts: [Account] = []
        var selectedAccount: Account? = nil
        var isLoading: Bool = false
        var error: String? = nil
        var successMessage: String? = nil

        private let accountRepository = AccountRepository.shared

        init() {
            Task { await loadAccounts() }
        }

        // MARK: - Accounts

        func loadAccounts() async {
            isLoading = true
            error = nil
            do {
                accounts = try await accountRepository.list()
                // Update selectedAccount if it exists in the new list
                if let selected = selectedAccount {
                    selectedAccount = accounts.first { $0.id == selected.id }
                }
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
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }

        func selectAccount(_ account: Account) {
            selectedAccount = account
        }

        func clearError() {
            error = nil
        }

        func clearSuccessMessage() {
            successMessage = nil
        }
    }
}
