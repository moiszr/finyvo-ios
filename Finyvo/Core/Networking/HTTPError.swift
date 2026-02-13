//
//  HTTPError.swift
//  Finyvo
//
//  Created by Moises Núñez on 02/12/26.
//  Tipos de error para la capa de networking.
//

import Foundation

// MARK: - HTTP Error

enum HTTPError: Error, LocalizedError, Sendable {
    /// 401 — Token inválido o expirado. NUNCA reintentar.
    case unauthorized(requestId: String?)

    /// 429 — Límite de peticiones excedido
    case rateLimited(retryAfter: TimeInterval?, requestId: String?)

    /// 5xx — Error del servidor
    case serverError(statusCode: Int, message: String?, requestId: String?)

    /// 400 — Petición inválida
    case badRequest(message: String, requestId: String?)

    /// 404 — Recurso no encontrado
    case notFound(requestId: String?)

    /// Error al decodificar la respuesta
    case decodingFailed(Error)

    /// Error de red (sin conexión, DNS, etc.)
    case networkError(Error)

    /// Timeout de la petición
    case timeout

    /// URL inválida
    case invalidURL

    // MARK: - Request ID

    var requestId: String? {
        switch self {
        case .unauthorized(let id): id
        case .rateLimited(_, let id): id
        case .serverError(_, _, let id): id
        case .badRequest(_, let id): id
        case .notFound(let id): id
        case .decodingFailed, .networkError, .timeout, .invalidURL: nil
        }
    }

    // MARK: - Localized Description

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            "Token de API inválido o expirado"
        case .rateLimited:
            "Demasiadas peticiones. Intenta de nuevo en unos momentos"
        case .serverError(let code, let message, _):
            "Error del servidor (\(code))\(message.map { ": \($0)" } ?? "")"
        case .badRequest(let message, _):
            "Petición inválida: \(message)"
        case .notFound:
            "Recurso no encontrado"
        case .decodingFailed:
            "Error al procesar la respuesta del servidor"
        case .networkError:
            "Error de conexión. Verifica tu internet"
        case .timeout:
            "La petición tardó demasiado tiempo"
        case .invalidURL:
            "URL inválida"
        }
    }
}

// MARK: - API Error Envelope

/// Envelope de error estándar del backend FinyvoRate
/// `{ "error": { "code": "RATE_LIMIT", "message": "...", "requestId": "..." } }`
struct APIErrorEnvelope: Decodable, Sendable {
    let error: APIErrorDetail

    struct APIErrorDetail: Decodable, Sendable {
        let code: String?
        let message: String?
        let requestId: String?
    }
}
