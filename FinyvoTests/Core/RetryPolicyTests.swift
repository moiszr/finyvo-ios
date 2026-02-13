//
//  RetryPolicyTests.swift
//  FinyvoTests
//
//  Created by Moises Núñez on 02/12/26.
//  Tests para RetryPolicy: elegibilidad y cálculo de delay.
//

import XCTest
@testable import Finyvo

final class RetryPolicyTests: XCTestCase {

    private let policy = RetryPolicy(maxAttempts: 3, baseDelay: 1.0, maxDelay: 8.0)

    // MARK: - Retry Eligibility

    func testShouldRetryOnRateLimited() {
        XCTAssertTrue(policy.shouldRetry(error: .rateLimited(retryAfter: nil, requestId: nil), attempt: 0))
        XCTAssertTrue(policy.shouldRetry(error: .rateLimited(retryAfter: nil, requestId: nil), attempt: 1))
        XCTAssertTrue(policy.shouldRetry(error: .rateLimited(retryAfter: nil, requestId: nil), attempt: 2))
    }

    func testShouldRetryOnServerError() {
        XCTAssertTrue(policy.shouldRetry(error: .serverError(statusCode: 500, message: nil, requestId: nil), attempt: 0))
        XCTAssertTrue(policy.shouldRetry(error: .serverError(statusCode: 502, message: nil, requestId: nil), attempt: 1))
    }

    func testShouldRetryOnTimeout() {
        XCTAssertTrue(policy.shouldRetry(error: .timeout, attempt: 0))
    }

    func testShouldRetryOnNetworkError() {
        let networkError = HTTPError.networkError(URLError(.notConnectedToInternet))
        XCTAssertTrue(policy.shouldRetry(error: networkError, attempt: 0))
    }

    func testShouldNotRetryOnUnauthorized() {
        XCTAssertFalse(policy.shouldRetry(error: .unauthorized(requestId: nil), attempt: 0))
    }

    func testShouldNotRetryOnBadRequest() {
        XCTAssertFalse(policy.shouldRetry(error: .badRequest(message: "bad", requestId: nil), attempt: 0))
    }

    func testShouldNotRetryOnNotFound() {
        XCTAssertFalse(policy.shouldRetry(error: .notFound(requestId: nil), attempt: 0))
    }

    func testShouldNotRetryOnDecodingFailed() {
        let error = HTTPError.decodingFailed(NSError(domain: "", code: 0))
        XCTAssertFalse(policy.shouldRetry(error: error, attempt: 0))
    }

    func testShouldNotRetryBeyondMaxAttempts() {
        XCTAssertFalse(policy.shouldRetry(error: .timeout, attempt: 3))
        XCTAssertFalse(policy.shouldRetry(error: .timeout, attempt: 10))
    }

    // MARK: - Delay Calculation

    func testDelayExponentialBackoff() {
        let delay0 = policy.delay(for: 0)
        let delay1 = policy.delay(for: 1)
        let delay2 = policy.delay(for: 2)

        // Delay base ~1s + jitter, ~2s + jitter, ~4s + jitter
        XCTAssertGreaterThanOrEqual(delay0, 1.0)
        XCTAssertLessThanOrEqual(delay0, 1.5)

        XCTAssertGreaterThanOrEqual(delay1, 2.0)
        XCTAssertLessThanOrEqual(delay1, 2.5)

        XCTAssertGreaterThanOrEqual(delay2, 4.0)
        XCTAssertLessThanOrEqual(delay2, 4.5)
    }

    func testDelayRespectsCap() {
        let delay = policy.delay(for: 10) // 2^10 * 1.0 = 1024, bien por encima del cap
        XCTAssertLessThanOrEqual(delay, 8.0)
    }
}
