//
//  HTTPClient.swift
//  Finyvo
//
//  Created by Moises Núñez on 02/12/26.
//  Cliente HTTP con reintentos, decodificación y manejo de errores.
//

import Foundation

// MARK: - Protocol

protocol HTTPClientProtocol: Sendable {
    func send<T: Decodable & Sendable>(_ endpoint: HTTPEndpoint, as type: T.Type) async throws -> T
    func sendRaw(_ endpoint: HTTPEndpoint) async throws -> Data
}

// MARK: - HTTP Client

final class HTTPClient: HTTPClientProtocol, Sendable {
    private let session: URLSession
    private let baseURL: URL
    private let tokenProvider: @Sendable () -> String?
    private let retryPolicy: RetryPolicy
    private let decoder: JSONDecoder

    init(
        session: URLSession = .shared,
        baseURL: URL,
        tokenProvider: @Sendable @escaping () -> String?,
        retryPolicy: RetryPolicy = RetryPolicy()
    ) {
        self.session = session
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        self.retryPolicy = retryPolicy

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    // MARK: - Send (Typed)

    func send<T: Decodable & Sendable>(_ endpoint: HTTPEndpoint, as type: T.Type) async throws -> T {
        let data = try await sendRaw(endpoint)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw HTTPError.decodingFailed(error)
        }
    }

    // MARK: - Send (Raw)

    func sendRaw(_ endpoint: HTTPEndpoint) async throws -> Data {
        let token = endpoint.requiresAuth ? tokenProvider() : nil
        let request: URLRequest
        do {
            request = try endpoint.urlRequest(baseURL: baseURL, token: token)
        } catch {
            throw error as? HTTPError ?? HTTPError.invalidURL
        }

        var lastError: HTTPError?

        for attempt in 0..<max(retryPolicy.maxAttempts, 1) {
            do {
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw HTTPError.networkError(
                        NSError(domain: "HTTPClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Respuesta no HTTP"])
                    )
                }

                #if DEBUG
                print("[HTTP] \(endpoint.method.rawValue) \(endpoint.path) → \(httpResponse.statusCode)")
                #endif

                if (200...299).contains(httpResponse.statusCode) {
                    return data
                }

                let httpError = Self.mapError(statusCode: httpResponse.statusCode, data: data, decoder: decoder)
                lastError = httpError

                if retryPolicy.shouldRetry(error: httpError, attempt: attempt) {
                    let delay = retryPolicy.delay(for: attempt)
                    try await Task.sleep(for: .seconds(delay))
                    continue
                }

                throw httpError

            } catch let error as HTTPError {
                lastError = error
                if retryPolicy.shouldRetry(error: error, attempt: attempt) {
                    let delay = retryPolicy.delay(for: attempt)
                    try await Task.sleep(for: .seconds(delay))
                    continue
                }
                throw error
            } catch let error as URLError where error.code == .timedOut {
                let httpError = HTTPError.timeout
                lastError = httpError
                if retryPolicy.shouldRetry(error: httpError, attempt: attempt) {
                    let delay = retryPolicy.delay(for: attempt)
                    try await Task.sleep(for: .seconds(delay))
                    continue
                }
                throw httpError
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                let httpError = HTTPError.networkError(error)
                lastError = httpError
                if retryPolicy.shouldRetry(error: httpError, attempt: attempt) {
                    let delay = retryPolicy.delay(for: attempt)
                    try await Task.sleep(for: .seconds(delay))
                    continue
                }
                throw httpError
            }
        }

        throw lastError ?? HTTPError.networkError(
            NSError(domain: "HTTPClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error desconocido"])
        )
    }

    // MARK: - Error Mapping

    private static func mapError(statusCode: Int, data: Data, decoder: JSONDecoder) -> HTTPError {
        let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data)
        let requestId = envelope?.error.requestId
        let message = envelope?.error.message

        switch statusCode {
        case 400:
            return .badRequest(message: message ?? "Petición inválida", requestId: requestId)
        case 401:
            return .unauthorized(requestId: requestId)
        case 404:
            return .notFound(requestId: requestId)
        case 429:
            return .rateLimited(retryAfter: nil, requestId: requestId)
        case 500...599:
            return .serverError(statusCode: statusCode, message: message, requestId: requestId)
        default:
            return .serverError(statusCode: statusCode, message: message ?? "Error inesperado", requestId: requestId)
        }
    }
}
