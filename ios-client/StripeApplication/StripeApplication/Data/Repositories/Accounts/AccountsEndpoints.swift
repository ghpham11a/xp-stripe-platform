import Foundation

enum AccountsEndpoints {
    struct Create: Endpoint {
        let path = "api/accounts"
        let method = HTTPMethod.post
        let body: Data?

        init(name: String, email: String) {
            self.body = try? JSONEncoder().encode(CreateAccountRequest(name: name, email: email))
        }
    }

    struct List: Endpoint {
        let path = "api/accounts"
    }

    struct Get: Endpoint {
        let path: String
        init(accountId: String) { path = "api/accounts/\(accountId)" }
    }

    struct Delete: Endpoint {
        let path: String
        let method = HTTPMethod.delete
        init(accountId: String) { path = "api/accounts/\(accountId)" }
    }

    struct UpgradeToRecipient: Endpoint {
        let path: String
        let method = HTTPMethod.post
        init(accountId: String) { path = "api/accounts/\(accountId)/upgrade-to-recipient" }
    }

    struct CreateOnboardingLink: Endpoint {
        let path: String
        let method = HTTPMethod.post
        let body: Data?

        init(accountId: String, refreshUrl: String, returnUrl: String) {
            path = "api/accounts/\(accountId)/onboarding-link"
            body = try? JSONEncoder().encode(AccountLinkRequest(refreshUrl: refreshUrl, returnUrl: returnUrl))
        }
    }
}
