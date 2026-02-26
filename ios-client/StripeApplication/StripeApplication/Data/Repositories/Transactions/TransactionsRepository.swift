import Foundation

final class TransactionsRepository: TransactionsRepo {
    private let networking: Networking

    init(networking: Networking) {
        self.networking = networking
    }

    func payUser(
        accountId: String,
        recipientAccountId: String,
        paymentMethodId: String,
        amount: Int
    ) async throws -> PayUserResponse {
        try await networking.makeRequest(endpoint: TransactionsEndpoints.PayUser(
            accountId: accountId,
            recipientAccountId: recipientAccountId,
            paymentMethodId: paymentMethodId,
            amount: amount
        ))
    }

    func createPaymentIntent(
        accountId: String,
        recipientAccountId: String,
        amount: Int,
        savePaymentMethod: Bool
    ) async throws -> CreatePaymentIntentResponse {
        try await networking.makeRequest(endpoint: TransactionsEndpoints.CreatePaymentIntent(
            accountId: accountId,
            recipientAccountId: recipientAccountId,
            amount: amount,
            savePaymentMethod: savePaymentMethod
        ))
    }
}
