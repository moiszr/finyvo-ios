//
//  FXEngineTests.swift
//  FinyvoTests
//
//  Created by Moises Núñez on 02/12/26.
//  Tests para FXEngine: conversión local, date routing, snapshot.
//

import XCTest
@testable import Finyvo

@MainActor
final class FXEngineTests: XCTestCase {

    private var service: FXService!
    private var engine: FXEngine!

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
        engine = FXEngine(service: service)
    }

    override func tearDown() {
        KeychainHelper.fxToken = nil
        MockURLProtocol.requestHandler = nil
        service = nil
        engine = nil
        super.tearDown()
    }

    // MARK: - Local Conversion

    func testConvertLocallyIdentity() async {
        service.configure(token: "token")
        MockURLProtocol.setSuccessResponse(json: [
            "base": "USD",
            "date_used": "2026-02-12",
            "rates": ["EUR": 0.92, "DOP": 59.1],
            "source": "kv"
        ])
        await service.fetchLatestRates()

        let result = engine.convertLocallyIfPossible(amount: 100, from: "USD", to: "USD")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.convertedAmount, 100)
        XCTAssertEqual(result!.rateUsed, 1.0)
        XCTAssertEqual(result!.source, "identity")
    }

    func testConvertLocallyFromBase() async {
        service.configure(token: "token")
        MockURLProtocol.setSuccessResponse(json: [
            "base": "USD",
            "date_used": "2026-02-12",
            "rates": ["DOP": 59.1],
            "source": "kv"
        ])
        await service.fetchLatestRates()

        let result = engine.convertLocallyIfPossible(amount: 100, from: "USD", to: "DOP")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.convertedAmount, 5910.0, accuracy: 0.01)
        XCTAssertEqual(result!.rateUsed, 59.1, accuracy: 0.001)
        XCTAssertEqual(result!.from, "USD")
        XCTAssertEqual(result!.to, "DOP")
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

        let result = engine.convertLocallyIfPossible(amount: 1000, from: "DOP", to: "EUR")
        XCTAssertNotNil(result)
        let expectedRate = 0.92 / 59.1
        XCTAssertEqual(result!.rateUsed, expectedRate, accuracy: 0.0001)
        XCTAssertEqual(result!.convertedAmount, 1000 * expectedRate, accuracy: 0.01)
    }

    func testConvertLocallyWithoutRates() {
        let result = engine.convertLocallyIfPossible(amount: 100, from: "USD", to: "EUR")
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

        let result = engine.convertLocallyIfPossible(amount: 100, from: "USD", to: "XYZ")
        XCTAssertNil(result)
    }

    // MARK: - Conversion Result Fields

    func testConversionResultContainsAllFields() async {
        service.configure(token: "token")
        MockURLProtocol.setSuccessResponse(json: [
            "base": "USD",
            "date_used": "2026-02-12",
            "rates": ["EUR": 0.92, "DOP": 59.1],
            "is_estimated": true,
            "source": "upstream"
        ])
        await service.fetchLatestRates()

        let result = engine.convertLocallyIfPossible(amount: 500, from: "USD", to: "DOP")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.originalAmount, 500)
        XCTAssertEqual(result!.from, "USD")
        XCTAssertEqual(result!.to, "DOP")
        XCTAssertEqual(result!.source, "upstream")
        XCTAssertTrue(result!.isEstimated)
    }

    // MARK: - Extract Rate

    func testExtractRateFromBase() {
        let snapshot = FXRateSnapshot(
            base: "USD",
            rates: ["EUR": 0.92, "DOP": 59.1],
            fetchedAt: Date(),
            isEstimated: false,
            source: "kv"
        )
        let rate = FXEngine.extractRate(from: "USD", to: "DOP", snapshot: snapshot)
        XCTAssertEqual(rate, 59.1)
    }

    func testExtractRateToBase() {
        let snapshot = FXRateSnapshot(
            base: "USD",
            rates: ["DOP": 59.1],
            fetchedAt: Date(),
            isEstimated: false,
            source: "kv"
        )
        let rate = FXEngine.extractRate(from: "DOP", to: "USD", snapshot: snapshot)
        XCTAssertNotNil(rate)
        XCTAssertEqual(rate!, 1.0 / 59.1, accuracy: 0.0001)
    }

    func testExtractRateCross() {
        let snapshot = FXRateSnapshot(
            base: "USD",
            rates: ["EUR": 0.92, "DOP": 59.1],
            fetchedAt: Date(),
            isEstimated: false,
            source: "kv"
        )
        let rate = FXEngine.extractRate(from: "DOP", to: "EUR", snapshot: snapshot)
        XCTAssertNotNil(rate)
        XCTAssertEqual(rate!, 0.92 / 59.1, accuracy: 0.0001)
    }

    func testExtractRateNotFound() {
        let snapshot = FXRateSnapshot(
            base: "USD",
            rates: ["EUR": 0.92],
            fetchedAt: Date(),
            isEstimated: false,
            source: "kv"
        )
        let rate = FXEngine.extractRate(from: "USD", to: "XYZ", snapshot: snapshot)
        XCTAssertNil(rate)
    }
}
