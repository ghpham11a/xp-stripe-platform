import Foundation

enum TransactionsEndpoints {
    struct PayUser: Endpoint {
        let path: String
        let method = HTTPMethod.post
        let body: Data?

        init(accountId: String, recipientAccountId: String, paymentMethodId: String, amount: Int) {
            path = "api/transactions/\(accountId)/pay-user"
            body = try? JSONEncoder().encode(PayUserRequest(
                amount: amount,
                recipientAccountId: recipientAccountId,
                paymentMethodId: paymentMethodId
            ))
        }
    }

    struct CreatePaymentIntent: Endpoint {
        let path: String
        let method = HTTPMethod.post
        let body: Data?

        init(accountId: String, recipientAccountId: String, amount: Int, savePaymentMethod: Bool) {
            path = "api/transactions/\(accountId)/create-payment-intent"
            body = try? JSONEncoder().encode(CreatePaymentIntentRequest(
                amount: amount,
                recipientAccountId: recipientAccountId,
                savePaymentMethod: savePaymentMethod
            ))
        }
    }
}
