import Foundation

struct AccountLinkRequest: Codable {
    let refreshUrl: String
    let returnUrl: String

    enum CodingKeys: String, CodingKey {
        case refreshUrl = "refresh_url"
        case returnUrl = "return_url"
    }
}

struct AccountLinkResponse: Codable {
    let url: String
    let created: String
    let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case url, created
        case expiresAt = "expires_at"
    }
}
