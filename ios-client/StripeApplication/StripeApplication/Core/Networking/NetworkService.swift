import Foundation
import os

final class NetworkService: Networking {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let defaultBaseURL: String
    private let maxRetries = 2

    init(baseURL: String? = nil) {
        self.defaultBaseURL = baseURL ?? Config.value(for: .apiURL)
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    func makeRequest<T: Decodable>(endpoint: any Endpoint) async throws -> T {
        let (data, _) = try await performRequest(endpoint: endpoint)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            Log.networking.error("Decoding error: \(error.localizedDescription)")
            throw NetworkError.decodingError("Failed to decode response: \(error.localizedDescription)")
        }
    }

    func makeRequestVoid(endpoint: any Endpoint) async throws {
        _ = try await performRequest(endpoint: endpoint)
    }

    func makeRawRequest(endpoint: any Endpoint) async throws -> (Data, HTTPURLResponse) {
        try await performRequest(endpoint: endpoint, skipErrorHandling: true)
    }

    // MARK: - Private

    private func performRequest(
        endpoint: any Endpoint,
        skipErrorHandling: Bool = false
    ) async throws -> (Data, HTTPURLResponse) {
        let request = try buildURLRequest(for: endpoint)
        let retries = endpoint.method == .get ? maxRetries : 0

        var lastError: Error?
        for attempt in 0...retries {
            if attempt > 0 {
                Log.networking.info("Retry attempt \(attempt) for \(endpoint.path)")
            }
            do {
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.networkError("Invalid response")
                }

                if skipErrorHandling {
                    return (data, httpResponse)
                }

                if httpResponse.statusCode == 401 {
                    Log.auth.warning("Received 401 for \(endpoint.path)")
                    throw NetworkError.unauthorized
                }

                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    return (data, httpResponse)
                }

                let errorMessage: String
                if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data),
                   let detail = errorResponse.detail {
                    errorMessage = detail
                } else {
                    errorMessage = "HTTP \(httpResponse.statusCode)"
                }
                throw NetworkError.serverError(errorMessage)
            } catch {
                lastError = error
                if error is NetworkError { throw error }
            }
        }

        throw lastError ?? NetworkError.networkError("Request failed")
    }

    private func buildURLRequest(for endpoint: any Endpoint) throws -> URLRequest {
        let base = endpoint.baseURL ?? defaultBaseURL
        let urlString = endpoint.baseURL != nil ? endpoint.path : "\(base)/\(endpoint.path)"

        guard var components = URLComponents(string: urlString) else {
            throw NetworkError.networkError("Invalid URL: \(urlString)")
        }

        if let queryItems = endpoint.queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw NetworkError.networkError("Invalid URL components")
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = endpoint.body

        return request
    }
}
