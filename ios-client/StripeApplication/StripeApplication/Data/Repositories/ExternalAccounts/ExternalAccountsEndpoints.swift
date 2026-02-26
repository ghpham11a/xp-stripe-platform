import Foundation

enum ExternalAccountsEndpoints {
    struct Create: Endpoint {
        let path: String
        let method = HTTPMethod.post
        let body: Data?

        init(accountId: String, token: String) {
            path = "api/accounts/\(accountId)/external-accounts"
            body = try? JSONEncoder().encode(CreateExternalAccountRequest(token: token))
        }
    }

    struct List: Endpoint {
        let path: String
        init(accountId: String) { path = "api/accounts/\(accountId)/external-accounts" }
    }

    struct Delete: Endpoint {
        let path: String
        let method = HTTPMethod.delete
        init(accountId: String, externalAccountId: String) {
            path = "api/accounts/\(accountId)/external-accounts/\(externalAccountId)"
        }
    }

    struct SetDefault: Endpoint {
        let path: String
        let method = HTTPMethod.patch
        init(accountId: String, externalAccountId: String) {
            path = "api/accounts/\(accountId)/external-accounts/\(externalAccountId)/default"
        }
    }

    struct CreateBankToken: Endpoint {
        let path = "v1/tokens"
        let method = HTTPMethod.post
        let baseURL: String? = "https://api.stripe.com"
        let headers: [String: String]
        let body: Data?

        init(accountHolderName: String, routingNumber: String, accountNumber: String) {
            headers = [
                "Authorization": "Bearer \(Config.stripePublishableKey)",
                "Content-Type": "application/x-www-form-urlencoded"
            ]

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

            body = bodyString.data(using: .utf8)
        }
    }
}
