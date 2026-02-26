import Foundation
import Observation

@Observable
class BankAccountsViewModel {
    let accountId: String
    var isRecipient: Bool

    var externalAccounts: [ExternalAccount] = []
    var isLoading: Bool = false
    var error: String? = nil
    var successMessage: String? = nil

    private let externalAccountsRepo: ExternalAccountsRepo

    init(accountId: String, isRecipient: Bool, externalAccountsRepo: ExternalAccountsRepo) {
        self.accountId = accountId
        self.isRecipient = isRecipient
        self.externalAccountsRepo = externalAccountsRepo
        Task { await loadExternalAccounts() }
    }

    func loadExternalAccounts() async {
        do {
            externalAccounts = try await externalAccountsRepo.list(accountId: accountId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createExternalAccount(token: String) async {
        isLoading = true
        error = nil
        do {
            _ = try await externalAccountsRepo.create(accountId: accountId, token: token)
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
            try await externalAccountsRepo.delete(accountId: accountId, externalAccountId: externalAccountId)
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
            _ = try await externalAccountsRepo.setDefault(accountId: accountId, externalAccountId: externalAccountId)
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
            let tokenId = try await externalAccountsRepo.createBankAccountToken(
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
