import Foundation

class ExternalAccountRepository {
    static let shared = ExternalAccountRepository()

    private let apiClient: APIClient

    private init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func create(accountId: String, token: String) async throws -> ExternalAccount {
        try await apiClient.request(
            method: "POST",
            path: "api/accounts/\(accountId)/external-accounts",
            body: CreateExternalAccountRequest(token: token)
        )
    }

    func list(accountId: String) async throws -> [ExternalAccount] {
        let response: ExternalAccountsResponse = try await apiClient.request(
            method: "GET",
            path: "api/accounts/\(accountId)/external-accounts"
        )
        return response.externalAccounts
    }

    func delete(accountId: String, externalAccountId: String) async throws {
        try await apiClient.requestVoid(
            method: "DELETE",
            path: "api/accounts/\(accountId)/external-accounts/\(externalAccountId)"
        )
    }

    func setDefault(accountId: String, externalAccountId: String) async throws -> ExternalAccount {
        try await apiClient.request(
            method: "PATCH",
            path: "api/accounts/\(accountId)/external-accounts/\(externalAccountId)/default"
        )
    }

    /// Creates a bank account token via direct Stripe API call
    func createBankAccountToken(
        accountHolderName: String,
        routingNumber: String,
        accountNumber: String
    ) async throws -> String {
        let url = URL(string: "https://api.stripe.com/v1/tokens")!

        let params = [
            "bank_account[country]": "US",
            "bank_account[currency]": "usd",
            "bank_account[routing_number]": routingNumber,
            "bank_account[account_number]": accountNumber,
            "bank_account[account_holder_name]": accountHolderName,
            "bank_account[account_holder_type]": "individual"
        ]

        let bodyString = params.map {
            "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)"
        }.joined(separator: "&")

        let headers = [
            "Authorization": "Bearer \(Config.stripePublishableKey)",
            "Content-Type": "application/x-www-form-urlencoded"
        ]

        let (data, httpResponse) = try await apiClient.requestExternalRaw(
            url: url,
            method: "POST",
            headers: headers,
            body: bodyString.data(using: .utf8)
        )

        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let tokenId = json["id"] as? String {
                return tokenId
            }
            throw APIError.decodingError("Failed to parse token response")
        } else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw APIError.serverError(message)
            }
            throw APIError.serverError("Failed to create bank token")
        }
    }
}
