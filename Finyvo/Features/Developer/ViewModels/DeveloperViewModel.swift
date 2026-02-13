//
//  DeveloperViewModel.swift
//  Finyvo
//
//  Created by Moises Núñez on 02/12/26.
//  ViewModel para la pantalla de desarrollador (gestión de token, pruebas de endpoints).
//

#if DEBUG
import Foundation
import Observation
import SwiftUI

// MARK: - Developer ViewModel

@Observable @MainActor
final class DeveloperViewModel {

    // MARK: - Token State

    var tokenInput = ""

    var isTokenSaved: Bool {
        KeychainHelper.fxToken != nil
    }

    var maskedToken: String {
        guard let token = KeychainHelper.fxToken else { return "No configurado" }
        let last4 = String(token.suffix(4))
        return "••••\(last4)"
    }

    // MARK: - Endpoint Tester

    var selectedEndpoint: TestableEndpoint = .health
    var testCurrencies = ""
    var testDate = ""
    var testStartDate = ""
    var testEndDate = ""
    var testFromCurrency = ""
    var testToCurrency = ""
    var testAmount = ""
    var testResult = ""
    var lastRequestId: String?
    var isTesting = false

    // MARK: - Cache Info

    var memoryCacheCount = 0
    var diskCacheCount = 0

    // MARK: - Actions

    func saveToken(service: FXService) {
        guard !tokenInput.isEmpty else { return }
        service.configure(token: tokenInput)
        tokenInput = ""
        Constants.Haptic.success()
    }

    func clearToken(service: FXService) {
        service.clearToken()
        Constants.Haptic.light()
    }

    func testEndpoint(service: FXService) async {
        isTesting = true
        testResult = ""
        lastRequestId = nil

        do {
            let result: String

            switch selectedEndpoint {
            case .health:
                let isHealthy = await service.checkHealth()
                result = isHealthy ? "✓ Servicio disponible" : "✗ Servicio no disponible"

            case .latest:
                let currencies = parseCurrencies(testCurrencies)
                await service.fetchLatestRates(currencies: currencies)
                if let rates = service.currentRates {
                    let ratesText = rates.rates
                        .sorted { $0.key < $1.key }
                        .prefix(20)
                        .map { "  \($0.key): \($0.value)" }
                        .joined(separator: "\n")
                    result = "Base: \(rates.base)\nFuente: \(rates.source)\nEstimado: \(rates.isEstimated)\n\nTasas:\n\(ratesText)"
                } else {
                    result = "Error: \(service.lastError?.localizedDescription ?? "desconocido")"
                }

            case .date:
                guard !testDate.isEmpty else {
                    testResult = "Error: fecha requerida (YYYY-MM-DD)"
                    isTesting = false
                    return
                }
                let currencies = parseCurrencies(testCurrencies)
                let response = try await service.fetchHistoricalRate(date: testDate, currencies: currencies)
                let ratesText = response.rates
                    .sorted { $0.key < $1.key }
                    .prefix(20)
                    .map { "  \($0.key): \($0.value)" }
                    .joined(separator: "\n")
                result = "Base: \(response.base)\nFecha usada: \(response.dateUsed)\nEstimado: \(response.isEstimated ?? false)\n\nTasas:\n\(ratesText)"

            case .timeframe:
                guard !testStartDate.isEmpty, !testEndDate.isEmpty else {
                    testResult = "Error: fechas de inicio y fin requeridas"
                    isTesting = false
                    return
                }
                let currencies = parseCurrencies(testCurrencies)
                let response = try await service.fetchTimeframe(start: testStartDate, end: testEndDate, currencies: currencies)
                let datesText = response.ratesByDate.keys.sorted().prefix(10).map { date in
                    let rates = response.ratesByDate[date] ?? [:]
                    let ratesStr = rates.sorted { $0.key < $1.key }.prefix(5).map { "\($0.key):\($0.value)" }.joined(separator: ", ")
                    return "  \(date): \(ratesStr)"
                }.joined(separator: "\n")
                result = "Base: \(response.base)\n\(response.start) → \(response.end)\n\nFechas:\n\(datesText)"

            case .convert:
                guard !testFromCurrency.isEmpty, !testToCurrency.isEmpty, !testAmount.isEmpty else {
                    testResult = "Error: from, to y amount requeridos"
                    isTesting = false
                    return
                }
                guard let amount = Double(testAmount) else {
                    testResult = "Error: monto inválido"
                    isTesting = false
                    return
                }
                let response = try await service.convert(amount: amount, from: testFromCurrency.uppercased(), to: testToCurrency.uppercased(), date: testDate.isEmpty ? nil : testDate)
                result = "\(response.amount) \(response.from) = \(response.result) \(response.to)\nTasa: \(response.rate)\nFecha usada: \(response.dateUsed ?? "N/A")\nEstimado: \(response.isEstimated ?? false)"

            case .symbols:
                let symbols = try await service.fetchSymbols()
                let symbolsText = symbols
                    .sorted { $0.key < $1.key }
                    .prefix(30)
                    .map { "  \($0.key): \($0.value)" }
                    .joined(separator: "\n")
                result = "Total: \(symbols.count) monedas\n\n\(symbolsText)"
            }

            testResult = result
            Constants.Haptic.success()

        } catch let error as FXError {
            testResult = "Error FX: \(error.localizedDescription)"
            if case .apiError(let httpError) = error {
                lastRequestId = httpError.requestId
            }
            Constants.Haptic.error()
        } catch let error as HTTPError {
            testResult = "Error HTTP: \(error.localizedDescription)"
            lastRequestId = error.requestId
            Constants.Haptic.error()
        } catch {
            testResult = "Error: \(error.localizedDescription)"
            Constants.Haptic.error()
        }

        isTesting = false
    }

    func refreshCacheInfo(service: FXService) async {
        memoryCacheCount = await service.memoryCacheCount()
        diskCacheCount = await service.diskCacheCount()
    }

    func clearCache(service: FXService) async {
        await service.clearCache()
        await refreshCacheInfo(service: service)
        Constants.Haptic.light()
    }

    func resetCircuit(service: FXService) {
        service.resetCircuitBreaker()
        Constants.Haptic.success()
    }

    func copyRequestId() {
        guard let requestId = lastRequestId else { return }
        UIPasteboard.general.string = requestId
        Constants.Haptic.light()
    }

    // MARK: - Helpers

    private func parseCurrencies(_ input: String) -> [String]? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
    }
}

// MARK: - Testable Endpoint

enum TestableEndpoint: String, CaseIterable, Identifiable {
    case health
    case latest
    case date
    case timeframe
    case convert
    case symbols

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .health: "GET /health"
        case .latest: "GET /fx/latest"
        case .date: "GET /fx/date/:date"
        case .timeframe: "GET /fx/timeframe"
        case .convert: "GET /fx/convert"
        case .symbols: "GET /fx/symbols"
        }
    }
}
#endif
