import Foundation

/// In-memory + on-disk LRU cache of translation results, keyed by (from, to, input).
/// A repeated lookup returns instantly and skips both the debounce and the network.
@MainActor
final class TranslationCache {
    static let shared = TranslationCache()

    private struct Entry: Codable {
        let key: String
        let output: TranslationOutput
    }

    private var map: [String: TranslationOutput] = [:]
    private var order: [String] = []           // least → most recently used
    private let capacity = 400

    private let fileURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent(AppInfo.name, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("translation-cache.json")
    }()
    private var saveTask: Task<Void, Never>?

    init() { load() }

    private func key(_ input: String, from: Language, to: Language) -> String {
        "\(from.code)>\(to.code)|\(input.lowercased())"
    }

    func get(_ input: String, from: Language, to: Language) -> TranslationOutput? {
        let k = key(input, from: from, to: to)
        guard let value = map[k] else { return nil }
        touch(k)
        return value
    }

    func set(_ output: TranslationOutput, input: String, from: Language, to: Language) {
        let k = key(input, from: from, to: to)
        map[k] = output
        touch(k)
        evictIfNeeded()
        scheduleSave()
    }

    // MARK: - LRU bookkeeping

    private func touch(_ k: String) {
        if let i = order.firstIndex(of: k) { order.remove(at: i) }
        order.append(k)
    }

    private func evictIfNeeded() {
        while order.count > capacity {
            map.removeValue(forKey: order.removeFirst())
        }
    }

    // MARK: - Persistence (debounced)

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let entries = try? JSONDecoder().decode([Entry].self, from: data) else { return }
        for entry in entries {
            map[entry.key] = entry.output
            order.append(entry.key)
        }
        evictIfNeeded()
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            self?.save()
        }
    }

    private func save() {
        let entries = order.compactMap { key in map[key].map { Entry(key: key, output: $0) } }
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
