import Foundation

protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: Data? { get }
    var queryItems: [URLQueryItem]? { get }
    var baseURL: String? { get }
}

extension Endpoint {
    var method: HTTPMethod { .get }
    var headers: [String: String] { ["Content-Type": "application/json"] }
    var body: Data? { nil }
    var queryItems: [URLQueryItem]? { nil }
    var baseURL: String? { nil }
}
