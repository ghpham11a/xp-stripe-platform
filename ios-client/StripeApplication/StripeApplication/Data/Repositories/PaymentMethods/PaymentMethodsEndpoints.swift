import Foundation

enum PaymentMethodsEndpoints {
    struct CreateSetupIntent: Endpoint {
        let path: String
        let method = HTTPMethod.post
        let queryItems: [URLQueryItem]?

        init(accountId: String, customerId: String?) {
            path = "api/accounts/\(accountId)/payment-methods/setup-intent"
            if let customerId {
                queryItems = [URLQueryItem(name: "customer_id", value: customerId)]
            } else {
                queryItems = nil
            }
        }
    }

    struct List: Endpoint {
        let path: String
        init(accountId: String) { path = "api/accounts/\(accountId)/payment-methods" }
    }

    struct Delete: Endpoint {
        let path: String
        let method = HTTPMethod.delete
        init(accountId: String, paymentMethodId: String) {
            path = "api/accounts/\(accountId)/payment-methods/\(paymentMethodId)"
        }
    }
}
