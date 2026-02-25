import Foundation
import Observation

@Observable
class HomeViewModel {
    var accounts: [Account] = []
    var selectedAccount: Account? = nil
    var isLoading: Bool = false
    var error: String? = nil
    var successMessage: String? = nil

    private let accountsRepo: AccountsRepo

    init(accountsRepo: AccountsRepo) {
        self.accountsRepo = accountsRepo
        Task { await loadAccounts() }
    }

    func loadAccounts() async {
        isLoading = true
        error = nil
        do {
            accounts = try await accountsRepo.list()
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
            let account = try await accountsRepo.create(name: name, email: email)
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
