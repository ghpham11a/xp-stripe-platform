import Foundation

final class AccountsRepository: AccountsRepo {
    private let networking: Networking

    init(networking: Networking) {
        self.networking = networking
    }

    func create(name: String, email: String) async throws -> Account {
        try await networking.makeRequest(endpoint: AccountsEndpoints.Create(name: name, email: email))
    }

    func list() async throws -> [Account] {
        let response: AccountsResponse = try await networking.makeRequest(endpoint: AccountsEndpoints.List())
        return response.accounts
    }

    func get(accountId: String) async throws -> Account {
        try await networking.makeRequest(endpoint: AccountsEndpoints.Get(accountId: accountId))
    }

    func delete(accountId: String) async throws {
        try await networking.makeRequestVoid(endpoint: AccountsEndpoints.Delete(accountId: accountId))
    }

    func upgradeToRecipient(accountId: String) async throws -> UpgradeToRecipientResponse {
        try await networking.makeRequest(endpoint: AccountsEndpoints.UpgradeToRecipient(accountId: accountId))
    }

    func createOnboardingLink(accountId: String, refreshUrl: String, returnUrl: String) async throws -> AccountLinkResponse {
        try await networking.makeRequest(endpoint: AccountsEndpoints.CreateOnboardingLink(
            accountId: accountId, refreshUrl: refreshUrl, returnUrl: returnUrl
        ))
    }
}
