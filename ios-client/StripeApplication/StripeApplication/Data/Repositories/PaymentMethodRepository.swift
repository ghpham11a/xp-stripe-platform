import Foundation

class PaymentMethodRepository {
    static let shared = PaymentMethodRepository()

    private let apiClient: APIClient

    private init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func createSetupIntent(accountId: String, customerId: String? = nil) async throws -> SetupIntentResponse {
        var queryItems: [URLQueryItem]? = nil
        if let customerId {
            queryItems = [URLQueryItem(name: "customer_id", value: customerId)]
        }
        return try await apiClient.request(
            method: "POST",
            path: "api/accounts/\(accountId)/payment-methods/setup-intent",
            queryItems: queryItems
        )
    }

    func list(accountId: String) async throws -> [PaymentMethod] {
        let response: PaymentMethodsResponse = try await apiClient.request(
            method: "GET",
            path: "api/accounts/\(accountId)/payment-methods"
        )
        return response.paymentMethods
    }

    func delete(accountId: String, paymentMethodId: String) async throws {
        try await apiClient.requestVoid(
            method: "DELETE",
            path: "api/accounts/\(accountId)/payment-methods/\(paymentMethodId)"
        )
    }
}
