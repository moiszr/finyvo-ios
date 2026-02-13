//
//  FXModels.swift
//  Finyvo
//
//  Created by Moises Núñez on 02/12/26.
//  Modelos Codable para las respuestas de FinyvoRate API.
//

import Foundation

// MARK: - Latest Response

/// `GET /fx/latest`
struct FXLatestResponse: Codable, Sendable {
    let base: String
    let requestedDate: String?
    let dateUsed: String
    let rates: [String: Double]
    let provider: String?
    let fetchedAt: String?
    let isEstimated: Bool?
    let source: String?
}

// MARK: - Convert Response

/// `GET /fx/convert`
struct FXConvertResponse: Codable, Sendable {
    let from: String
    let to: String
    let amount: Double
    let rate: Double
    let result: Double
    let base: String
    let requestedDate: String?
    let dateUsed: String?
    let provider: String?
    let fetchedAt: String?
    let isEstimated: Bool?
    let source: String?
}

// MARK: - Date Response

/// `GET /fx/date/:date`
struct FXDateResponse: Codable, Sendable {
    let base: String
    let requestedDate: String?
    let dateUsed: String
    let rates: [String: Double]
    let provider: String?
    let fetchedAt: String?
    let isEstimated: Bool?
    let source: String?
}

// MARK: - Timeframe Response

/// `GET /fx/timeframe`
struct FXTimeframeResponse: Codable, Sendable {
    let base: String
    let start: String
    let end: String
    let ratesByDate: [String: [String: Double]]
    let provider: String?
    let fetchedAt: String?
    let source: String?
}

// MARK: - Symbols Response

/// `GET /fx/symbols`
struct FXSymbolsResponse: Codable, Sendable {
    let symbols: [String: String]
    let provider: String?
    let fetchedAt: String?
    let source: String?
}

// MARK: - Rate Snapshot (Domain Model)

/// Snapshot local de tasas que expone FXService
struct FXRateSnapshot: Sendable {
    let base: String
    let rates: [String: Double]
    let fetchedAt: Date
    let isEstimated: Bool
    let source: String

    /// Verifica si el snapshot ha expirado según el TTL dado
    func isExpired(ttl: TimeInterval = AppConfig.FinyvoRate.latestCacheTTL) -> Bool {
        Date().timeIntervalSince(fetchedAt) > ttl
    }

    /// Tiempo transcurrido desde la última actualización
    var age: TimeInterval {
        Date().timeIntervalSince(fetchedAt)
    }
}
