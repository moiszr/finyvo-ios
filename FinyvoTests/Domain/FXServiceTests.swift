//
//  FXServiceTests.swift
//  FinyvoTests
//
//  Created by Moises Núñez on 02/12/26.
//  Tests para FXService: fetch, convert, circuit breaker, token lifecycle.
//

import XCTest
@testable import Finyvo

@MainActor
final class FXServiceTests: XCTestCase {

    private var service: FXService!

    override func setUp() {
        super.setUp()
        let session = MockURLProtocol.mockSession()
        let client = HTTPClient(
            session: session,
            baseURL: URL(string: "https://test.finyvo.com")!,
            tokenProvider: { KeychainHelper.fxToken },
            retryPolicy: RetryPolicy(maxAttempts: 1)
        )
        service = FXService(client: client)
    }

    override func tearDown() {
        KeychainHelper.fxToken = nil
        MockURLProtocol.requestHandler = nil
        service = nil
        super.tearDown()
    }

    // MARK: - Token Management

    func testConfigureToken() {
        XCTAssertFalse(service.isConfigured)
        service.configure(token: "test-token")
        XCTAssertTrue(service.isConfigured)
    }

    func testClearToken() {
        service.configure(token: "test-token")
        service.clearToken()
        XCTAssertFalse(service.isConfigured)
    }

    // MARK: - Fetch Latest

    func testFetchLatestWithoutToken() async {
        await service.fetchLatestRates()
        XCTAssertNotNil(service.lastError)
        if case .noToken = service.lastError {
            // Correcto
        } else {
            XCTFail("Debió ser noToken: \(String(describing: service.lastError))")
        }
    }

    func testFetchLatestSuccess() async {
        service.configure(token: "valid-token")

        MockURLProtocol.setSuccessResponse(json: [
            "base": "USD",
            "date_used": "2026-02-12",
            "rates": ["EUR": 0.92, "DOP": 59.1],
            "is_estimated": false,
            "source": "kv"
        ])

        await service.fetchLatestRates()

        XCTAssertNotNil(service.currentRates)
        XCTAssertEqual(service.currentRates?.base, "USD")
        XCTAssertEqual(service.currentRates?.rates["EUR"], 0.92)
        XCTAssertNil(service.lastError)
    }

    // MARK: - Circuit Breaker

    func testCircuitBreakerOpensOn401() async {
        service.configure(token: "bad-token")

        MockURLProtocol.setErrorResponse(
            statusCode: 401,
            code: "UNAUTHORIZED",
            message: "Invalid key"
        )

        await service.fetchLatestRates()

        XCTAssertTrue(service.isCircuitOpen)
        XCTAssertEqual(service.consecutiveAuthFailures, 1)
    }

    func testCircuitBreakerBlocksSubsequentCalls() async {
        service.configure(token: "bad-token")
        service.resetCircuitBreaker()

        // Abrir el circuit breaker
        MockURLProtocol.setErrorResponse(statusCode: 401, code: "UNAUTHORIZED", message: "Invalid")
        await service.fetchLatestRates()
        XCTAssertTrue(service.isCircuitOpen)

        // Intentar otra petición — debe bloquearse sin hacer request
        var requestMade = false
        MockURLProtocol.requestHandler = { _ in
            requestMade = true
            return (HTTPURLResponse(url: URL(string: "https://test.finyvo.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data())
        }

        await service.fetchLatestRates()
        XCTAssertFalse(requestMade, "No debió hacer request con circuit breaker abierto")
    }

    func testResetCircuitBreaker() {
        service.configure(token: "token")
        // Simular estado abierto
        service.resetCircuitBreaker()
        XCTAssertFalse(service.isCircuitOpen)
        XCTAssertEqual(service.consecutiveAuthFailures, 0)
    }

    // MARK: - Local Conversion

    func testConvertLocallySameCurrency() async {
        service.configure(token: "token")

        MockURLProtocol.setSuccessResponse(json: [
            "base": "USD",
            "date_used": "2026-02-12",
            "rates": ["EUR": 0.92, "DOP": 59.1],
            "source": "kv"
        ])

        await service.fetchLatestRates()

        let result = service.convertLocally(amount: 100, from: "USD", to: "USD")
        XCTAssertEqual(result, 100)
    }

    func testConvertLocallyFromBase() async {
        service.configure(token: "token")

        MockURLProtocol.setSuccessResponse(json: [
            "base": "USD",
            "date_used": "2026-02-12",
            "rates": ["EUR": 0.92, "DOP": 59.1],
            "source": "kv"
        ])

        await service.fetchLatestRates()

        let result = service.convertLocally(amount: 100, from: "USD", to: "DOP")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 5910.0, accuracy: 0.01)
    }

    func testConvertLocallyToBase() async {
        service.configure(token: "token")

        MockURLProtocol.setSuccessResponse(json: [
            "base": "USD",
            "date_used": "2026-02-12",
            "rates": ["DOP": 59.1],
            "source": "kv"
        ])

        await service.fetchLatestRates()

        let result = service.convertLocally(amount: 5910, from: "DOP", to: "USD")
        XCTAssertEqual(result!, 100.0, accuracy: 0.01)
    }

    func testConvertLocallyCrossRate() async {
        service.configure(token: "token")

        MockURLProtocol.setSuccessResponse(json: [
            "base": "USD",
            "date_used": "2026-02-12",
            "rates": ["EUR": 0.92, "DOP": 59.1],
            "source": "kv"
        ])

        await service.fetchLatestRates()

        // DOP → EUR: rates[EUR] / rates[DOP] = 0.92 / 59.1
        let result = service.convertLocally(amount: 1000, from: "DOP", to: "EUR")
        let expected = 1000 * (0.92 / 59.1)
        XCTAssertEqual(result!, expected, accuracy: 0.001)
    }

    func testConvertLocallyWithoutRates() {
        let result = service.convertLocally(amount: 100, from: "USD", to: "EUR")
        XCTAssertNil(result)
    }

    func testConvertLocallyUnsupportedCurrency() async {
        service.configure(token: "token")

        MockURLProtocol.setSuccessResponse(json: [
            "base": "USD",
            "date_used": "2026-02-12",
            "rates": ["EUR": 0.92],
            "source": "kv"
        ])

        await service.fetchLatestRates()

        let result = service.convertLocally(amount: 100, from: "USD", to: "XYZ")
        XCTAssertNil(result)
    }

    // MARK: - Health Check

    func testHealthCheckSuccess() async {
        MockURLProtocol.setSuccessResponse(json: ["status": "ok"])
        let isHealthy = await service.checkHealth()
        XCTAssertTrue(isHealthy)
    }

    func testHealthCheckFailure() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        let isHealthy = await service.checkHealth()
        XCTAssertFalse(isHealthy)
    }
}
