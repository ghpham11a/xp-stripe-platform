import Foundation

final class ExternalAccountsRepository: ExternalAccountsRepo {
    private let networking: Networking

    init(networking: Networking) {
        self.networking = networking
    }

    func create(accountId: String, token: String) async throws -> ExternalAccount {
        try await networking.makeRequest(endpoint: ExternalAccountsEndpoints.Create(
            accountId: accountId, token: token
        ))
    }

    func list(accountId: String) async throws -> [ExternalAccount] {
        let response: ExternalAccountsResponse = try await networking.makeRequest(
            endpoint: ExternalAccountsEndpoints.List(accountId: accountId)
        )
        return response.externalAccounts
    }

    func delete(accountId: String, externalAccountId: String) async throws {
        try await networking.makeRequestVoid(endpoint: ExternalAccountsEndpoints.Delete(
            accountId: accountId, externalAccountId: externalAccountId
        ))
    }

    func setDefault(accountId: String, externalAccountId: String) async throws -> ExternalAccount {
        try await networking.makeRequest(endpoint: ExternalAccountsEndpoints.SetDefault(
            accountId: accountId, externalAccountId: externalAccountId
        ))
    }

    func createBankAccountToken(
        accountHolderName: String,
        routingNumber: String,
        accountNumber: String
    ) async throws -> String {
        let endpoint = ExternalAccountsEndpoints.CreateBankToken(
            accountHolderName: accountHolderName,
            routingNumber: routingNumber,
            accountNumber: accountNumber
        )

        let (data, httpResponse) = try await networking.makeRawRequest(endpoint: endpoint)

        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let tokenId = json["id"] as? String {
                return tokenId
            }
            throw NetworkError.decodingError("Failed to parse token response")
        } else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw NetworkError.serverError(message)
            }
            throw NetworkError.serverError("Failed to create bank token")
        }
    }
}
