import Foundation

enum APIError: Error, LocalizedError {
    case networkError(String)
    case serverError(String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return msg
        case .serverError(let msg): return msg
        case .decodingError(let msg): return msg
        }
    }
}

class APIClient {
    static let shared = APIClient()

    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        self.baseURL = Config.apiURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    private func request<T: Decodable>(
        method: String,
        path: String,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        var components = URLComponents(string: "\(baseURL)/\(path)")!
        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response")
        }

        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError("Failed to decode response: \(error.localizedDescription)")
            }
        } else {
            let errorMessage: String
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data),
               let detail = errorResponse.detail {
                errorMessage = detail
            } else {
                errorMessage = "HTTP \(httpResponse.statusCode)"
            }
            throw APIError.serverError(errorMessage)
        }
    }

    private func requestVoid(
        method: String,
        path: String,
        body: (any Encodable)? = nil
    ) async throws {
        var components = URLComponents(string: "\(baseURL)/\(path)")!

        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response")
        }

        if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
            let errorMessage: String
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data),
               let detail = errorResponse.detail {
                errorMessage = detail
            } else {
                errorMessage = "HTTP \(httpResponse.statusCode)"
            }
            throw APIError.serverError(errorMessage)
        }
    }

    // MARK: - Account APIs

    func createAccount(name: String, email: String) async throws -> Account {
        try await request(
            method: "POST",
            path: "api/accounts",
            body: CreateAccountRequest(name: name, email: email)
        )
    }

    func listAccounts() async throws -> [Account] {
        let response: AccountsResponse = try await request(method: "GET", path: "api/accounts")
        return response.accounts
    }

    func getAccount(accountId: String) async throws -> Account {
        try await request(method: "GET", path: "api/accounts/\(accountId)")
    }

    func deleteAccount(accountId: String) async throws {
        try await requestVoid(method: "DELETE", path: "api/accounts/\(accountId)")
    }

    func upgradeToRecipient(accountId: String) async throws -> UpgradeToRecipientResponse {
        try await request(method: "POST", path: "api/accounts/\(accountId)/upgrade-to-recipient")
    }

    func createOnboardingLink(accountId: String, refreshUrl: String, returnUrl: String) async throws -> AccountLinkResponse {
        try await request(
            method: "POST",
            path: "api/accounts/\(accountId)/onboarding-link",
            body: AccountLinkRequest(refreshUrl: refreshUrl, returnUrl: returnUrl)
        )
    }

    // MARK: - Payment Method APIs

    func createSetupIntent(accountId: String, customerId: String? = nil) async throws -> SetupIntentResponse {
        var queryItems: [URLQueryItem]? = nil
        if let customerId {
            queryItems = [URLQueryItem(name: "customer_id", value: customerId)]
        }
        return try await request(
            method: "POST",
            path: "api/accounts/\(accountId)/payment-methods/setup-intent",
            queryItems: queryItems
        )
    }

    func listPaymentMethods(accountId: String) async throws -> [PaymentMethod] {
        let response: PaymentMethodsResponse = try await request(
            method: "GET",
            path: "api/accounts/\(accountId)/payment-methods"
        )
        return response.paymentMethods
    }

    func deletePaymentMethod(accountId: String, paymentMethodId: String) async throws {
        try await requestVoid(
            method: "DELETE",
            path: "api/accounts/\(accountId)/payment-methods/\(paymentMethodId)"
        )
    }

    // MARK: - External Account APIs

    func createExternalAccount(accountId: String, token: String) async throws -> ExternalAccount {
        try await request(
            method: "POST",
            path: "api/accounts/\(accountId)/external-accounts",
            body: CreateExternalAccountRequest(token: token)
        )
    }

    func listExternalAccounts(accountId: String) async throws -> [ExternalAccount] {
        let response: ExternalAccountsResponse = try await request(
            method: "GET",
            path: "api/accounts/\(accountId)/external-accounts"
        )
        return response.externalAccounts
    }

    func deleteExternalAccount(accountId: String, externalAccountId: String) async throws {
        try await requestVoid(
            method: "DELETE",
            path: "api/accounts/\(accountId)/external-accounts/\(externalAccountId)"
        )
    }

    func setDefaultExternalAccount(accountId: String, externalAccountId: String) async throws -> ExternalAccount {
        try await request(
            method: "PATCH",
            path: "api/accounts/\(accountId)/external-accounts/\(externalAccountId)/default"
        )
    }

    // MARK: - Transaction APIs

    func payUser(accountId: String, recipientAccountId: String, paymentMethodId: String, amount: Int) async throws -> PayUserResponse {
        try await request(
            method: "POST",
            path: "api/transactions/\(accountId)/pay-user",
            body: PayUserRequest(amount: amount, recipientAccountId: recipientAccountId, paymentMethodId: paymentMethodId)
        )
    }

    func createPaymentIntent(accountId: String, recipientAccountId: String, amount: Int, savePaymentMethod: Bool) async throws -> CreatePaymentIntentResponse {
        try await request(
            method: "POST",
            path: "api/transactions/\(accountId)/create-payment-intent",
            body: CreatePaymentIntentRequest(amount: amount, recipientAccountId: recipientAccountId, savePaymentMethod: savePaymentMethod)
        )
    }

    // MARK: - Stripe Token API (direct call to Stripe for bank account tokens)

    func createBankAccountToken(
        accountHolderName: String,
        routingNumber: String,
        accountNumber: String
    ) async throws -> String {
        let url = URL(string: "https://api.stripe.com/v1/tokens")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.stripePublishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params = [
            "bank_account[country]": "US",
            "bank_account[currency]": "usd",
            "bank_account[routing_number]": routingNumber,
            "bank_account[account_number]": accountNumber,
            "bank_account[account_holder_name]": accountHolderName,
            "bank_account[account_holder_type]": "individual"
        ]

        let bodyString = params.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response")
        }

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
