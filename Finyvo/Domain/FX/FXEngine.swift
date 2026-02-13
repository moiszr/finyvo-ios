//
//  FXEngine.swift
//  Finyvo
//
//  Created by Moises Núñez on 02/12/26.
//  Motor de conversión de monedas con routing date-aware.
//

import Foundation

// MARK: - FX Conversion Result

/// Resultado de una conversión de moneda.
struct FXConversionResult: Sendable {
    let originalAmount: Double
    let convertedAmount: Double
    let rateUsed: Double
    let from: String
    let to: String
    let asOfDate: Date
    let source: String
    let isEstimated: Bool
}

// MARK: - FX Engine

/// Motor de conversión que encapsula la lógica de routing date-aware.
///
/// - Fecha de hoy → usa `/fx/latest` (cached en FXService)
/// - Fecha histórica → usa `/fx/date/:date`
/// - Conversión local → usa tasas en memoria sin red
@MainActor
struct FXEngine {

    private let service: FXService

    init(service: FXService) {
        self.service = service
    }

    // MARK: - Server Conversion (date-aware)

    /// Convierte un monto con routing date-aware.
    ///
    /// - Si `date` es hoy: usa las tasas más recientes (`/fx/latest`)
    /// - Si `date` es histórica: usa `/fx/date/:date`
    /// - Retorna `FXConversionResult` con toda la metadata
    func convertedAmount(
        amount: Double,
        from: String,
        to: String,
        on date: Date
    ) async throws -> FXConversionResult {
        guard from != to else {
            return FXConversionResult(
                originalAmount: amount,
                convertedAmount: amount,
                rateUsed: 1.0,
                from: from,
                to: to,
                asOfDate: date,
                source: "identity",
                isEstimated: false
            )
        }

        let dateString = Self.dateFormatter.string(from: date)

        if date.isToday {
            // Fecha de hoy → /fx/latest + conversión local
            await service.fetchLatestRates(currencies: [from, to])

            if let snapshot = service.currentRates,
               let rate = Self.extractRate(from: from, to: to, snapshot: snapshot) {
                return FXConversionResult(
                    originalAmount: amount,
                    convertedAmount: amount * rate,
                    rateUsed: rate,
                    from: from,
                    to: to,
                    asOfDate: snapshot.fetchedAt,
                    source: snapshot.source,
                    isEstimated: snapshot.isEstimated
                )
            }

            // Fallback al endpoint /fx/convert
            let response = try await service.convert(amount: amount, from: from, to: to)
            return FXConversionResult(
                originalAmount: amount,
                convertedAmount: response.result,
                rateUsed: response.rate,
                from: from,
                to: to,
                asOfDate: date,
                source: response.source ?? "server",
                isEstimated: response.isEstimated ?? false
            )
        } else {
            // Fecha histórica → /fx/date/:date
            let response = try await service.convert(
                amount: amount,
                from: from,
                to: to,
                date: dateString
            )
            return FXConversionResult(
                originalAmount: amount,
                convertedAmount: response.result,
                rateUsed: response.rate,
                from: from,
                to: to,
                asOfDate: date,
                source: response.source ?? "historical",
                isEstimated: response.isEstimated ?? false
            )
        }
    }

    // MARK: - Local Conversion (sin red)

    /// Convierte usando las tasas en memoria. Retorna nil si no hay tasas disponibles.
    func convertLocallyIfPossible(
        amount: Double,
        from: String,
        to: String
    ) -> FXConversionResult? {
        guard from != to else {
            return FXConversionResult(
                originalAmount: amount,
                convertedAmount: amount,
                rateUsed: 1.0,
                from: from,
                to: to,
                asOfDate: Date(),
                source: "identity",
                isEstimated: false
            )
        }

        guard let snapshot = service.currentRates,
              let rate = Self.extractRate(from: from, to: to, snapshot: snapshot) else {
            return nil
        }

        return FXConversionResult(
            originalAmount: amount,
            convertedAmount: amount * rate,
            rateUsed: rate,
            from: from,
            to: to,
            asOfDate: snapshot.fetchedAt,
            source: snapshot.source,
            isEstimated: snapshot.isEstimated
        )
    }

    // MARK: - Helpers

    /// Extrae la tasa de conversión de un snapshot.
    static func extractRate(from: String, to: String, snapshot: FXRateSnapshot) -> Double? {
        let base = snapshot.base
        let rates = snapshot.rates

        if from == base {
            return rates[to]
        } else if to == base {
            return rates[from].map { 1.0 / $0 }
        } else if let toRate = rates[to], let fromRate = rates[from] {
            return toRate / fromRate
        }
        return nil
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
