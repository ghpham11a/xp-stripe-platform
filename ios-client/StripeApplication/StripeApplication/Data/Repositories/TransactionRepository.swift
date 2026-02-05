import Foundation

class TransactionRepository {
    static let shared = TransactionRepository()

    private let apiClient: APIClient

    private init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func payUser(
        accountId: String,
        recipientAccountId: String,
        paymentMethodId: String,
        amount: Int
    ) async throws -> PayUserResponse {
        try await apiClient.request(
            method: "POST",
            path: "api/transactions/\(accountId)/pay-user",
            body: PayUserRequest(
                amount: amount,
                recipientAccountId: recipientAccountId,
                paymentMethodId: paymentMethodId
            )
        )
    }

    func createPaymentIntent(
        accountId: String,
        recipientAccountId: String,
        amount: Int,
        savePaymentMethod: Bool
    ) async throws -> CreatePaymentIntentResponse {
        try await apiClient.request(
            method: "POST",
            path: "api/transactions/\(accountId)/create-payment-intent",
            body: CreatePaymentIntentRequest(
                amount: amount,
                recipientAccountId: recipientAccountId,
                savePaymentMethod: savePaymentMethod
            )
        )
    }
}
