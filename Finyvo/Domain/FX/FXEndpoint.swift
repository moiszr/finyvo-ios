//
//  FXEndpoint.swift
//  Finyvo
//
//  Created by Moises Núñez on 02/12/26.
//  Fábrica de endpoints tipados para FinyvoRate API.
//

import Foundation

// MARK: - FX Endpoint

enum FXEndpoint {

    /// `GET /health` — sin autenticación
    static func health() -> HTTPEndpoint {
        HTTPEndpoint(
            path: "/health",
            requiresAuth: false
        )
    }

    /// `GET /fx/latest` — tasas más recientes
    static func latest(currencies: [String]? = nil) -> HTTPEndpoint {
        HTTPEndpoint(
            path: "/fx/latest",
            queryItems: currencyQueryItems(currencies),
            cacheTTL: AppConfig.FinyvoRate.latestCacheTTL
        )
    }

    /// `GET /fx/date/:date` — tasas históricas
    static func date(_ date: String, currencies: [String]? = nil) -> HTTPEndpoint {
        HTTPEndpoint(
            path: "/fx/date/\(date)",
            queryItems: currencyQueryItems(currencies)
        )
    }

    /// `GET /fx/timeframe` — rango de fechas
    static func timeframe(start: String, end: String, currencies: [String]? = nil) -> HTTPEndpoint {
        var items = [
            URLQueryItem(name: "start", value: start),
            URLQueryItem(name: "end", value: end)
        ]
        if let currencies, !currencies.isEmpty {
            items.append(URLQueryItem(name: "currencies", value: currencies.joined(separator: ",")))
        }
        return HTTPEndpoint(
            path: "/fx/timeframe",
            queryItems: items
        )
    }

    /// `GET /fx/convert` — conversión de moneda
    static func convert(from: String, to: String, amount: Double, date: String? = nil) -> HTTPEndpoint {
        var items = [
            URLQueryItem(name: "from", value: from),
            URLQueryItem(name: "to", value: to),
            URLQueryItem(name: "amount", value: String(amount))
        ]
        if let date {
            items.append(URLQueryItem(name: "date", value: date))
        }
        return HTTPEndpoint(
            path: "/fx/convert",
            queryItems: items
        )
    }

    /// `GET /fx/symbols` — diccionario de monedas
    static func symbols() -> HTTPEndpoint {
        HTTPEndpoint(
            path: "/fx/symbols",
            cacheTTL: AppConfig.FinyvoRate.symbolsCacheTTL
        )
    }

    // MARK: - Helpers

    private static func currencyQueryItems(_ currencies: [String]?) -> [URLQueryItem] {
        guard let currencies, !currencies.isEmpty else { return [] }
        return [URLQueryItem(name: "currencies", value: currencies.joined(separator: ","))]
    }
}
