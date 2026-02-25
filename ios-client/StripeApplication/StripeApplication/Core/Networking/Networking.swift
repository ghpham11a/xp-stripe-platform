import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum NetworkError: Error, LocalizedError {
    case networkError(String)
    case serverError(String)
    case decodingError(String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return msg
        case .serverError(let msg): return msg
        case .decodingError(let msg): return msg
        case .unauthorized: return "Unauthorized"
        }
    }
}

protocol Networking {
    func makeRequest<T: Decodable>(endpoint: any Endpoint) async throws -> T
    func makeRequestVoid(endpoint: any Endpoint) async throws
    func makeRawRequest(endpoint: any Endpoint) async throws -> (Data, HTTPURLResponse)
}
