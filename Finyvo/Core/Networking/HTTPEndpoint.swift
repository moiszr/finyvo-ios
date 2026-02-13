//
//  HTTPEndpoint.swift
//  Finyvo
//
//  Created by Moises Núñez on 02/12/26.
//  Descriptor de petición HTTP para construir URLRequests.
//

import Foundation

// MARK: - HTTP Method

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
}

// MARK: - HTTP Endpoint

struct HTTPEndpoint: Sendable {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]
    let requiresAuth: Bool
    let cacheTTL: TimeInterval?

    init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool = true,
        cacheTTL: TimeInterval? = nil
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.requiresAuth = requiresAuth
        self.cacheTTL = cacheTTL
    }

    // MARK: - Build Request

    /// Construye un URLRequest a partir de este endpoint
    func urlRequest(baseURL: URL, token: String?) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)

        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw HTTPError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Finyvo/\(AppConfig.appVersion)", forHTTPHeaderField: "User-Agent")

        if requiresAuth, let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    /// Clave de cache basada en path + query
    var cacheKey: String {
        var key = path
        if !queryItems.isEmpty {
            let params = queryItems
                .sorted { $0.name < $1.name }
                .map { "\($0.name)=\($0.value ?? "")" }
                .joined(separator: "&")
            key += "?\(params)"
        }
        return key
    }
}

// MARK: - CustomStringConvertible

extension HTTPEndpoint: CustomStringConvertible {
    /// Descripción segura — NUNCA incluye headers de autenticación
    var description: String {
        "\(method.rawValue) \(path)\(queryItems.isEmpty ? "" : "?\(queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&"))")"
    }
}
