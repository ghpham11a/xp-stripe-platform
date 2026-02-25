import Foundation
import Observation

@Observable
class AccountViewModel {
    var account: Account
    var isLoading: Bool = false
    var error: String? = nil
    var successMessage: String? = nil
    var onboardingUrl: String? = nil
    var wasDeleted: Bool = false

    private let accountsRepo: AccountsRepo

    init(account: Account, accountsRepo: AccountsRepo) {
        self.account = account
        self.accountsRepo = accountsRepo
    }

    func loadAccount() async {
        do {
            account = try await accountsRepo.get(accountId: account.id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteAccount() async {
        isLoading = true
        error = nil
        do {
            try await accountsRepo.delete(accountId: account.id)
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
            _ = try await accountsRepo.upgradeToRecipient(accountId: account.id)
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
            let response = try await accountsRepo.createOnboardingLink(
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
