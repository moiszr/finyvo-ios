//
//  FXCacheTests.swift
//  FinyvoTests
//
//  Created by Moises Núñez on 02/12/26.
//  Tests para FXCache: TTL, staleness, coalescing, persistencia en disco.
//

import XCTest
@testable import Finyvo

final class FXCacheTests: XCTestCase {

    private var cache: FXCache!

    override func setUp() async throws {
        cache = FXCache()
        await cache.clearAll()
    }

    override func tearDown() async throws {
        await cache.clearAll()
        cache = nil
    }

    // MARK: - Basic Operations

    func testSetAndGet() async {
        let data = "test-data".data(using: .utf8)!
        await cache.set(data, for: "key1", ttl: 3600)

        let entry = await cache.get(for: "key1")
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.data, data)
    }

    func testGetNonExistent() async {
        let entry = await cache.get(for: "nonexistent")
        XCTAssertNil(entry)
    }

    // MARK: - TTL / Expiration

    func testEntryNotExpiredWithinTTL() async {
        let data = "fresh".data(using: .utf8)!
        await cache.set(data, for: "fresh-key", ttl: 3600)

        let entry = await cache.get(for: "fresh-key")
        XCTAssertNotNil(entry)
        XCTAssertFalse(entry!.isExpired)
    }

    func testEntryExpiredAfterTTL() async {
        // Crear una entrada con TTL de 0 segundos (expira inmediatamente)
        let data = "stale".data(using: .utf8)!
        await cache.set(data, for: "stale-key", ttl: 0)

        let entry = await cache.get(for: "stale-key")
        XCTAssertNotNil(entry) // Todavía retorna la entrada stale
        XCTAssertTrue(entry!.isExpired)
    }

    // MARK: - Coalescing

    func testGetOrFetchCoalescing() async throws {
        var fetchCount = 0

        // Lanzar múltiples peticiones concurrentes con la misma key
        async let result1: Data = cache.getOrFetch(key: "coalesce", ttl: 3600) {
            fetchCount += 1
            try await Task.sleep(for: .milliseconds(100))
            return "shared-result".data(using: .utf8)!
        }

        async let result2: Data = cache.getOrFetch(key: "coalesce", ttl: 3600) {
            fetchCount += 1
            try await Task.sleep(for: .milliseconds(100))
            return "shared-result".data(using: .utf8)!
        }

        let (data1, data2) = try await (result1, result2)

        XCTAssertEqual(data1, data2)
        // Solo debe haber ejecutado el fetch una vez (coalescing)
        XCTAssertEqual(fetchCount, 1)
    }

    func testGetOrFetchReturnsCachedData() async throws {
        let data = "cached".data(using: .utf8)!
        await cache.set(data, for: "cached-key", ttl: 3600)

        var fetchCalled = false
        let result = try await cache.getOrFetch(key: "cached-key", ttl: 3600) {
            fetchCalled = true
            return "fresh".data(using: .utf8)!
        }

        XCTAssertEqual(result, data)
        XCTAssertFalse(fetchCalled, "No debió ejecutar fetch con cache fresco")
    }

    func testGetOrFetchReturnsStaleOnFailure() async {
        // Primero: guardar datos que expiran inmediatamente
        let staleData = "stale-data".data(using: .utf8)!
        await cache.set(staleData, for: "stale-fetch", ttl: 0)

        do {
            let result = try await cache.getOrFetch(key: "stale-fetch", ttl: 3600) {
                throw URLError(.notConnectedToInternet)
            }

            // Debe devolver los datos stale
            XCTAssertEqual(result, staleData)
        } catch {
            XCTFail("Debió retornar datos stale, no lanzar error: \(error)")
        }
    }

    // MARK: - Clear

    func testClearAll() async {
        await cache.set("a".data(using: .utf8)!, for: "k1", ttl: 3600)
        await cache.set("b".data(using: .utf8)!, for: "k2", ttl: 3600)

        await cache.clearAll()

        let count = await cache.memoryCacheCount
        XCTAssertEqual(count, 0)
    }

    func testClearExpired() async {
        await cache.set("fresh".data(using: .utf8)!, for: "fresh", ttl: 3600)
        await cache.set("expired".data(using: .utf8)!, for: "expired", ttl: 0)

        await cache.clearExpired()

        let freshEntry = await cache.get(for: "fresh")
        let expiredEntry = await cache.get(for: "expired")

        XCTAssertNotNil(freshEntry)
        XCTAssertNil(expiredEntry)
    }

    // MARK: - Counts

    func testCacheCount() async {
        await cache.set("a".data(using: .utf8)!, for: "k1", ttl: 3600)
        await cache.set("b".data(using: .utf8)!, for: "k2", ttl: 3600)

        let memoryCount = await cache.memoryCacheCount
        XCTAssertEqual(memoryCount, 2)

        let diskCount = await cache.diskCacheCount
        XCTAssertEqual(diskCount, 2)
    }
}
