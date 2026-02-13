//
//  FXIntegrationTests.swift
//  FinyvoTests
//
//  Created by Moises Núñez on 02/12/26.
//  Tests de integración: estadísticas convertidas, snapshot FX, preferredCurrencyCode.
//

import XCTest
@testable import Finyvo

@MainActor
final class FXIntegrationTests: XCTestCase {

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
        UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.preferredCurrencyCode)
        super.tearDown()
    }

    // MARK: - Converted Statistics

    func testConvertedStatisticsWithSameCurrency() async {
        service.configure(token: "token")
        MockURLProtocol.setSuccessResponse(json: [
            "base": "USD",
            "date_used": "2026-02-12",
            "rates": ["EUR": 0.92, "DOP": 59.1],
            "source": "kv"
        ])
        await service.fetchLatestRates()

        let transactions = [
            Transaction(amount: 1000, type: .income),
            Transaction(amount: 500, type: .expense),
        ]
        // Sin wallet, safeCurrencyCode = AppConfig.Defaults.currencyCode = "USD"

        let vm = TransactionsViewModel()
        let stats = vm.calculateConvertedStatistics(
            from: transactions,
            preferredCurrency: "USD",
            fxService: service
        )

        // Misma moneda, sin conversión
        XCTAssertEqual(stats.totalIncome, 1000)
        XCTAssertEqual(stats.totalExpenses, 500)
        XCTAssertEqual(stats.incomeCount, 1)
        XCTAssertEqual(stats.expenseCount, 1)
    }

    func testConvertedStatisticsWithDifferentCurrency() async {
        service.configure(token: "token")
        MockURLProtocol.setSuccessResponse(json: [
            "base": "USD",
            "date_used": "2026-02-12",
            "rates": ["EUR": 0.92, "DOP": 59.1],
            "source": "kv"
        ])
        await service.fetchLatestRates()

        // Transacciones en USD (sin wallet = USD por defecto)
        let transactions = [
            Transaction(amount: 1000, type: .income),
            Transaction(amount: 500, type: .expense),
        ]

        let vm = TransactionsViewModel()
        let stats = vm.calculateConvertedStatistics(
            from: transactions,
            preferredCurrency: "DOP",
            fxService: service
        )

        // USD → DOP: amount * 59.1
        XCTAssertEqual(stats.totalIncome, 1000 * 59.1, accuracy: 0.01)
        XCTAssertEqual(stats.totalExpenses, 500 * 59.1, accuracy: 0.01)
    }

    func testConvertedStatisticsWithoutRates() {
        // Sin tasas cargadas, debe usar montos originales
        let transactions = [
            Transaction(amount: 1000, type: .income),
            Transaction(amount: 500, type: .expense),
        ]

        let vm = TransactionsViewModel()
        let stats = vm.calculateConvertedStatistics(
            from: transactions,
            preferredCurrency: "DOP",
            fxService: service
        )

        // Sin conversión disponible, usa montos originales
        XCTAssertEqual(stats.totalIncome, 1000)
        XCTAssertEqual(stats.totalExpenses, 500)
    }

    // MARK: - Transaction FX Snapshot

    func testTransactionFXSnapshotFields() {
        let tx = Transaction(amount: 100, type: .expense)
        XCTAssertNil(tx.fxRate)
        XCTAssertNil(tx.fxAsOfDate)
        XCTAssertNil(tx.fxPreferredCurrencyCode)
        XCTAssertNil(tx.fxSource)
        XCTAssertFalse(tx.fxIsEstimated)
        XCTAssertFalse(tx.hasFXSnapshot)
        XCTAssertNil(tx.fxConvertedAmount)
        XCTAssertNil(tx.formattedFXAmount)

        // Simular snapshot
        tx.fxRate = 59.1
        tx.fxAsOfDate = Date()
        tx.fxPreferredCurrencyCode = "DOP"
        tx.fxSource = "kv"
        tx.fxIsEstimated = false

        XCTAssertTrue(tx.hasFXSnapshot)
        XCTAssertEqual(tx.fxConvertedAmount!, 100 * 59.1, accuracy: 0.01)
        XCTAssertNotNil(tx.formattedFXAmount)
    }

    // MARK: - Preferred Currency Code Persistence

    func testPreferredCurrencyCodePersistence() {
        let appState = AppState()

        // Default
        XCTAssertEqual(appState.preferredCurrencyCode, AppConfig.Defaults.currencyCode)

        // Cambiar
        appState.preferredCurrencyCode = "DOP"
        XCTAssertEqual(appState.preferredCurrencyCode, "DOP")

        // Verificar persistencia en UserDefaults
        let stored = UserDefaults.standard.string(forKey: Constants.StorageKeys.preferredCurrencyCode)
        XCTAssertEqual(stored, "DOP")

        // Crear nueva instancia y verificar que persiste
        let appState2 = AppState()
        XCTAssertEqual(appState2.preferredCurrencyCode, "DOP")
    }

    func testPreferredCurrencyCodeDefault() {
        UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.preferredCurrencyCode)
        let appState = AppState()
        XCTAssertEqual(appState.preferredCurrencyCode, "USD")
    }
}
