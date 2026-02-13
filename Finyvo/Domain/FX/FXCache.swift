//
//  FXCache.swift
//  Finyvo
//
//  Created by Moises Núñez on 02/12/26.
//  Cache actor con memoria + disco, TTL y coalescing de peticiones.
//

import Foundation

// MARK: - FX Cache

actor FXCache {

    // MARK: - Cache Entry

    struct CacheEntry: Codable, Sendable {
        let data: Data
        let timestamp: Date
        let ttl: TimeInterval

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > ttl
        }

        var isStale: Bool {
            isExpired
        }

        var age: TimeInterval {
            Date().timeIntervalSince(timestamp)
        }
    }

    // MARK: - State

    private var memory: [String: CacheEntry] = [:]
    private var inflight: [String: Task<Data, Error>] = [:]
    private let diskURL: URL

    // MARK: - Init

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskURL = caches.appendingPathComponent("FinyvoFX", isDirectory: true)

        // Crear directorio si no existe
        try? FileManager.default.createDirectory(at: diskURL, withIntermediateDirectories: true)
    }

    // MARK: - Get

    /// Obtiene una entrada del cache (memoria primero, luego disco)
    func get(for key: String) -> CacheEntry? {
        // Memoria primero
        if let entry = memory[key] {
            return entry
        }

        // Fallback a disco
        if let entry = loadFromDisk(key: key) {
            memory[key] = entry
            return entry
        }

        return nil
    }

    // MARK: - Set

    /// Guarda datos en memoria y disco
    func set(_ data: Data, for key: String, ttl: TimeInterval) {
        let entry = CacheEntry(data: data, timestamp: Date(), ttl: ttl)
        memory[key] = entry
        saveToDisk(entry, key: key)
    }

    // MARK: - Get or Fetch (Coalescing)

    /// Obtiene del cache o ejecuta el fetch con coalescing de peticiones concurrentes
    func getOrFetch(key: String, ttl: TimeInterval, fetch: @Sendable @escaping () async throws -> Data) async throws -> Data {
        // Cache hit fresco
        if let entry = get(for: key), !entry.isExpired {
            return entry.data
        }

        // Coalescing: reusar petición en vuelo
        if let existingTask = inflight[key] {
            return try await existingTask.value
        }

        let staleEntry = get(for: key)

        let task = Task<Data, Error> {
            try await fetch()
        }

        inflight[key] = task

        do {
            let data = try await task.value
            inflight[key] = nil
            set(data, for: key, ttl: ttl)
            return data
        } catch {
            inflight[key] = nil
            // Si hay datos stale, devolverlos en vez de fallar
            if let staleEntry {
                return staleEntry.data
            }
            throw error
        }
    }

    // MARK: - Maintenance

    /// Elimina todo el cache (memoria y disco)
    func clearAll() {
        memory.removeAll()
        try? FileManager.default.removeItem(at: diskURL)
        try? FileManager.default.createDirectory(at: diskURL, withIntermediateDirectories: true)
    }

    /// Elimina entradas expiradas
    func clearExpired() {
        let expiredKeys = memory.filter { $0.value.isExpired }.map(\.key)
        for key in expiredKeys {
            memory.removeValue(forKey: key)
            deleteDiskEntry(key: key)
        }
    }

    /// Número de entradas en memoria
    var memoryCacheCount: Int {
        memory.count
    }

    /// Número de entradas en disco
    var diskCacheCount: Int {
        let files = try? FileManager.default.contentsOfDirectory(at: diskURL, includingPropertiesForKeys: nil)
        return files?.count ?? 0
    }

    // MARK: - Disk Persistence

    private func diskPath(for key: String) -> URL {
        let safeKey = key
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "&", with: "_")
            .replacingOccurrences(of: "=", with: "_")
        return diskURL.appendingPathComponent(safeKey).appendingPathExtension("cache")
    }

    private func saveToDisk(_ entry: CacheEntry, key: String) {
        let path = diskPath(for: key)
        try? JSONEncoder().encode(entry).write(to: path, options: .atomic)
    }

    private func loadFromDisk(key: String) -> CacheEntry? {
        let path = diskPath(for: key)
        guard let data = try? Data(contentsOf: path) else { return nil }
        return try? JSONDecoder().decode(CacheEntry.self, from: data)
    }

    private func deleteDiskEntry(key: String) {
        let path = diskPath(for: key)
        try? FileManager.default.removeItem(at: path)
    }
}
