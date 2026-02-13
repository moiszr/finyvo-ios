//
//  FXService.swift
//  Finyvo
//
//  Created by Moises Núñez on 02/12/26.
//  Servicio principal de tasas de cambio con cache y circuit breaker.
//

import Foundation
import Observation

// MARK: - FX Service

@Observable @MainActor
final class FXService {

    // MARK: - Published State

    /// Snapshot actual de tasas de cambio
    private(set) var currentRates: FXRateSnapshot?

    /// Indicador de carga
    private(set) var isLoading = false

    /// Último error de dominio
    private(set) var lastError: FXError?

    /// Token disponible (app-owned, no expuesto al usuario)
    var isConfigured: Bool {
        Self.tokenProvider() != nil
    }

    /// Circuit breaker abierto por 401
    private(set) var isCircuitOpen = false

    /// Contador de fallos consecutivos de auth
    private(set) var consecutiveAuthFailures = 0

    // MARK: - Private

    private let client: HTTPClient
    private let cache: FXCache

    /// Proveedor interno del token (app-owned, no expuesto al usuario)
    static let tokenProvider: @Sendable () -> String? = {
        let token = Secrets.fxAPIToken
        return token != "TU_TOKEN_AQUI" ? token : nil
    }

    // MARK: - Init

    init() {
        let baseURL = URL(string: AppConfig.FinyvoRate.baseURL)!

        self.client = HTTPClient(
            baseURL: baseURL,
            tokenProvider: Self.tokenProvider
        )
        self.cache = FXCache()
    }

    /// Init para testing con client inyectado
    init(client: HTTPClient, cache: FXCache = FXCache()) {
        self.client = client
        self.cache = cache
    }

    // MARK: - Token Management (Debug Only)

    #if DEBUG
    /// Configura el token de API y resetea el circuit breaker (solo desarrollo)
    func configure(token: String) {
        KeychainHelper.fxToken = token
        isCircuitOpen = false
        consecutiveAuthFailures = 0
        lastError = nil
    }

    /// Elimina el token de API (solo desarrollo)
    func clearToken() {
        KeychainHelper.fxToken = nil
        currentRates = nil
        lastError = nil
    }
    #endif

    /// Resetea el circuit breaker manualmente
    func resetCircuitBreaker() {
        isCircuitOpen = false
        consecutiveAuthFailures = 0
        lastError = nil
    }

    // MARK: - Fetch Latest Rates

    /// Obtiene las tasas más recientes (cache-first)
    func fetchLatestRates(currencies: [String]? = nil) async {
        guard AppConfig.isFXEnabled else { return }
        guard !isCircuitOpen else {
            lastError = .circuitOpen
            return
        }
        guard isConfigured else {
            lastError = .noToken
            return
        }

        isLoading = true
        lastError = nil

        do {
            let endpoint = FXEndpoint.latest(currencies: currencies)
            let ttl = endpoint.cacheTTL ?? AppConfig.FinyvoRate.latestCacheTTL

            let data = try await cache.getOrFetch(key: endpoint.cacheKey, ttl: ttl) { [client] in
                try await client.sendRaw(endpoint)
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(FXLatestResponse.self, from: data)

            currentRates = FXRateSnapshot(
                base: response.base,
                rates: response.rates,
                fetchedAt: Date(),
                isEstimated: response.isEstimated ?? false,
                source: response.source ?? "unknown"
            )

            consecutiveAuthFailures = 0
            isLoading = false

        } catch let error as HTTPError {
            isLoading = false
            handleHTTPError(error)
        } catch {
            isLoading = false
            lastError = .apiError(.networkError(error))
        }
    }

    // MARK: - Convert (Server)

    /// Convierte un monto usando el endpoint del servidor
    func convert(amount: Double, from: String, to: String, date: String? = nil) async throws -> FXConvertResponse {
        guard AppConfig.isFXEnabled else { throw FXError.noToken }
        try checkCircuitAndToken()

        let endpoint = FXEndpoint.convert(from: from, to: to, amount: amount, date: date)

        do {
            let data = try await client.sendRaw(endpoint)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(FXConvertResponse.self, from: data)
            consecutiveAuthFailures = 0
            return response
        } catch let error as HTTPError {
            handleHTTPError(error)
            throw lastError ?? .apiError(error)
        }
    }

    // MARK: - Convert (Local)

    /// Convierte un monto usando las tasas locales (sin red)
    /// Retorna nil si no hay tasas disponibles o la conversión no es posible
    func convertLocally(amount: Double, from: String, to: String) -> Double? {
        guard let snapshot = currentRates else { return nil }
        guard from != to else { return amount }

        let base = snapshot.base
        let rates = snapshot.rates

        let rate: Double?

        if from == base {
            rate = rates[to]
        } else if to == base {
            rate = rates[from].map { 1.0 / $0 }
        } else {
            // Cross rate: rates[to] / rates[from]
            if let toRate = rates[to], let fromRate = rates[from] {
                rate = toRate / fromRate
            } else {
                rate = nil
            }
        }

        guard let rate else { return nil }
        return amount * rate
    }

    // MARK: - Symbols

    /// Obtiene el diccionario de símbolos de monedas (7d cache)
    func fetchSymbols() async throws -> [String: String] {
        guard AppConfig.isFXEnabled else { throw FXError.noToken }
        try checkCircuitAndToken()

        let endpoint = FXEndpoint.symbols()
        let ttl = endpoint.cacheTTL ?? AppConfig.FinyvoRate.symbolsCacheTTL

        do {
            let data = try await cache.getOrFetch(key: endpoint.cacheKey, ttl: ttl) { [client] in
                try await client.sendRaw(endpoint)
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(FXSymbolsResponse.self, from: data)
            consecutiveAuthFailures = 0
            return response.symbols
        } catch let error as HTTPError {
            handleHTTPError(error)
            throw lastError ?? .apiError(error)
        }
    }

    // MARK: - Historical Rate

    /// Obtiene tasas históricas para una fecha
    func fetchHistoricalRate(date: String, currencies: [String]? = nil) async throws -> FXDateResponse {
        guard AppConfig.isFXEnabled else { throw FXError.noToken }
        try checkCircuitAndToken()

        let endpoint = FXEndpoint.date(date, currencies: currencies)

        do {
            let data = try await client.sendRaw(endpoint)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(FXDateResponse.self, from: data)
            consecutiveAuthFailures = 0
            return response
        } catch let error as HTTPError {
            handleHTTPError(error)
            throw lastError ?? .apiError(error)
        }
    }

    // MARK: - Timeframe

    /// Obtiene tasas para un rango de fechas
    func fetchTimeframe(start: String, end: String, currencies: [String]? = nil) async throws -> FXTimeframeResponse {
        guard AppConfig.isFXEnabled else { throw FXError.noToken }
        try checkCircuitAndToken()

        let endpoint = FXEndpoint.timeframe(start: start, end: end, currencies: currencies)

        do {
            let data = try await client.sendRaw(endpoint)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(FXTimeframeResponse.self, from: data)
            consecutiveAuthFailures = 0
            return response
        } catch let error as HTTPError {
            handleHTTPError(error)
            throw lastError ?? .apiError(error)
        }
    }

    // MARK: - Health Check

    /// Verifica si el backend está disponible (no requiere token)
    func checkHealth() async -> Bool {
        do {
            let _: Data = try await client.sendRaw(FXEndpoint.health())
            return true
        } catch {
            return false
        }
    }

    // MARK: - Cache Management

    /// Limpia todo el cache
    func clearCache() async {
        await cache.clearAll()
    }

    /// Número de entradas en cache de memoria
    func memoryCacheCount() async -> Int {
        await cache.memoryCacheCount
    }

    /// Número de entradas en cache de disco
    func diskCacheCount() async -> Int {
        await cache.diskCacheCount
    }

    // MARK: - Private Helpers

    private func checkCircuitAndToken() throws {
        if isCircuitOpen {
            throw FXError.circuitOpen
        }
        if !isConfigured {
            throw FXError.noToken
        }
    }

    private func handleHTTPError(_ error: HTTPError) {
        switch error {
        case .unauthorized:
            consecutiveAuthFailures += 1
            isCircuitOpen = true
            lastError = .circuitOpen
        case .rateLimited:
            lastError = .rateLimited
        default:
            lastError = .apiError(error)
        }
    }
}
