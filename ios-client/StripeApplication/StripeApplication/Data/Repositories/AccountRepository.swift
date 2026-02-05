import Foundation

class AccountRepository {
    static let shared = AccountRepository()

    private let apiClient: APIClient

    private init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func create(name: String, email: String) async throws -> Account {
        try await apiClient.request(
            method: "POST",
            path: "api/accounts",
            body: CreateAccountRequest(name: name, email: email)
        )
    }

    func list() async throws -> [Account] {
        let response: AccountsResponse = try await apiClient.request(
            method: "GET",
            path: "api/accounts"
        )
        return response.accounts
    }

    func get(accountId: String) async throws -> Account {
        try await apiClient.request(
            method: "GET",
            path: "api/accounts/\(accountId)"
        )
    }

    func delete(accountId: String) async throws {
        try await apiClient.requestVoid(
            method: "DELETE",
            path: "api/accounts/\(accountId)"
        )
    }

    func upgradeToRecipient(accountId: String) async throws -> UpgradeToRecipientResponse {
        try await apiClient.request(
            method: "POST",
            path: "api/accounts/\(accountId)/upgrade-to-recipient"
        )
    }

    func createOnboardingLink(accountId: String, refreshUrl: String, returnUrl: String) async throws -> AccountLinkResponse {
        try await apiClient.request(
            method: "POST",
            path: "api/accounts/\(accountId)/onboarding-link",
            body: AccountLinkRequest(refreshUrl: refreshUrl, returnUrl: returnUrl)
        )
    }
}
