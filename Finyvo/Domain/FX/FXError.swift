//
//  FXError.swift
//  Finyvo
//
//  Created by Moises Núñez on 02/12/26.
//  Errores de dominio para el módulo de tasas de cambio.
//

import Foundation

// MARK: - FX Error

enum FXError: Error, LocalizedError, Identifiable, Sendable {
    /// No hay token de API configurado
    case noToken

    /// Circuit breaker abierto por fallo de autenticación
    case circuitOpen

    /// Límite de peticiones excedido
    case rateLimited

    /// Sin conexión a internet
    case networkUnavailable

    /// Datos obsoletos disponibles pero no frescos
    case staleData(lastFetched: Date)

    /// No se pudo convertir entre las monedas especificadas
    case conversionFailed(from: String, to: String)

    /// Moneda no soportada por el backend
    case unsupportedCurrency(code: String)

    /// Error de la capa HTTP
    case apiError(HTTPError)

    // MARK: - Identifiable

    var id: String { localizedDescription }

    // MARK: - Localized Description

    var errorDescription: String? {
        switch self {
        case .noToken:
            "No hay token de API configurado"
        case .circuitOpen:
            "Servicio de tasas deshabilitado por error de autenticación"
        case .rateLimited:
            "Demasiadas peticiones. Intenta más tarde"
        case .networkUnavailable:
            "Sin conexión a internet"
        case .staleData(let date):
            "Datos desactualizados (última actualización: \(date.formatted(.relative(presentation: .named))))"
        case .conversionFailed(let from, let to):
            "No se pudo convertir de \(from) a \(to)"
        case .unsupportedCurrency(let code):
            "Moneda no soportada: \(code)"
        case .apiError(let error):
            error.localizedDescription
        }
    }
}
