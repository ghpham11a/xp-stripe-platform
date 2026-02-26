import Foundation

protocol TransactionsRepo {
    func payUser(accountId: String, recipientAccountId: String, paymentMethodId: String, amount: Int) async throws -> PayUserResponse
    func createPaymentIntent(accountId: String, recipientAccountId: String, amount: Int, savePaymentMethod: Bool) async throws -> CreatePaymentIntentResponse
}
