//
//  RetryPolicy.swift
//  Finyvo
//
//  Created by Moises Núñez on 02/12/26.
//  Política de reintentos con backoff exponencial y jitter.
//

import Foundation

// MARK: - Retry Policy

struct RetryPolicy: Sendable {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval

    init(
        maxAttempts: Int = AppConfig.FinyvoRate.maxRetryAttempts,
        baseDelay: TimeInterval = AppConfig.FinyvoRate.retryBaseDelay,
        maxDelay: TimeInterval = AppConfig.FinyvoRate.retryMaxDelay
    ) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
    }

    // MARK: - Retry Eligibility

    /// Determina si un error es elegible para reintento
    func shouldRetry(error: HTTPError, attempt: Int) -> Bool {
        guard attempt < maxAttempts else { return false }

        switch error {
        case .rateLimited:
            return true
        case .serverError:
            return true
        case .timeout:
            return true
        case .networkError:
            return true
        case .unauthorized, .badRequest, .notFound, .decodingFailed, .invalidURL:
            return false
        }
    }

    // MARK: - Delay Calculation

    /// Calcula el delay para un intento con backoff exponencial + jitter
    func delay(for attempt: Int) -> TimeInterval {
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...0.5)
        return min(exponentialDelay + jitter, maxDelay)
    }
}
