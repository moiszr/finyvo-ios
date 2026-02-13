//
//  KeychainHelperTests.swift
//  FinyvoTests
//
//  Created by Moises Núñez on 02/12/26.
//  Tests para KeychainHelper: save/load/delete round-trip.
//

import XCTest
@testable import Finyvo

final class KeychainHelperTests: XCTestCase {

    private let testKey = "com.finyvo.test.keychainHelper"

    override func tearDown() {
        KeychainHelper.delete(for: testKey)
        super.tearDown()
    }

    // MARK: - Round Trip

    func testSaveAndLoad() {
        let value = "test-secret-value"
        let saved = KeychainHelper.saveString(value, for: testKey)
        XCTAssertTrue(saved)

        let loaded = KeychainHelper.loadString(for: testKey)
        XCTAssertEqual(loaded, value)
    }

    func testLoadNonExistent() {
        let loaded = KeychainHelper.loadString(for: "non-existent-key-\(UUID().uuidString)")
        XCTAssertNil(loaded)
    }

    func testDelete() {
        KeychainHelper.saveString("to-be-deleted", for: testKey)
        let deleted = KeychainHelper.delete(for: testKey)
        XCTAssertTrue(deleted)

        let loaded = KeychainHelper.loadString(for: testKey)
        XCTAssertNil(loaded)
    }

    func testOverwrite() {
        KeychainHelper.saveString("original", for: testKey)
        KeychainHelper.saveString("updated", for: testKey)

        let loaded = KeychainHelper.loadString(for: testKey)
        XCTAssertEqual(loaded, "updated")
    }

    // MARK: - FX Token Convenience

    func testFXTokenGetSet() {
        // Limpiar primero
        KeychainHelper.fxToken = nil
        XCTAssertNil(KeychainHelper.fxToken)

        KeychainHelper.fxToken = "fx-test-token-abc"
        XCTAssertEqual(KeychainHelper.fxToken, "fx-test-token-abc")

        KeychainHelper.fxToken = nil
        XCTAssertNil(KeychainHelper.fxToken)
    }
}
