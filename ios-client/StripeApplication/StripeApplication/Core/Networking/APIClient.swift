import Foundation

enum APIError: Error, LocalizedError {
    case networkError(String)
    case serverError(String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return msg
        case .serverError(let msg): return msg
        case .decodingError(let msg): return msg
        }
    }
}

class APIClient {
    static let shared = APIClient()

    let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        self.baseURL = Config.apiURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    func request<T: Decodable>(
        method: String,
        path: String,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        var components = URLComponents(string: "\(baseURL)/\(path)")!
        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response")
        }

        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError("Failed to decode response: \(error.localizedDescription)")
            }
        } else {
            let errorMessage: String
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data),
               let detail = errorResponse.detail {
                errorMessage = detail
            } else {
                errorMessage = "HTTP \(httpResponse.statusCode)"
            }
            throw APIError.serverError(errorMessage)
        }
    }

    func requestVoid(
        method: String,
        path: String,
        body: (any Encodable)? = nil
    ) async throws {
        let components = URLComponents(string: "\(baseURL)/\(path)")!

        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response")
        }

        if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
            let errorMessage: String
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data),
               let detail = errorResponse.detail {
                errorMessage = detail
            } else {
                errorMessage = "HTTP \(httpResponse.statusCode)"
            }
            throw APIError.serverError(errorMessage)
        }
    }

    func requestExternal<T>(
        url: URL,
        method: String,
        headers: [String: String],
        body: Data?
    ) async throws -> T where T: Decodable {
        var request = URLRequest(url: url)
        request.httpMethod = method
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response")
        }

        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            return try decoder.decode(T.self, from: data)
        } else {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
    }

    func requestExternalRaw(
        url: URL,
        method: String,
        headers: [String: String],
        body: Data?
    ) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response")
        }

        return (data, httpResponse)
    }
}
