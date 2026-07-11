import Foundation

/// Persists bookmarks to `~/Library/Application Support/Reversobar/bookmarks.json`.
@MainActor
final class BookmarkStore: ObservableObject {
    static let shared = BookmarkStore()

    @Published private(set) var items: [Bookmark] = []

    private let fileURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent(AppInfo.name, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("bookmarks.json")
    }()

    init() { load() }

    func contains(_ bookmark: Bookmark) -> Bool {
        items.contains { $0.key == bookmark.key }
    }

    /// Adds the bookmark if absent, removes it if present (newest first).
    func toggle(_ bookmark: Bookmark) {
        if let idx = items.firstIndex(where: { $0.key == bookmark.key }) {
            items.remove(at: idx)
        } else {
            items.insert(bookmark, at: 0)
        }
        save()
    }

    func remove(_ bookmark: Bookmark) {
        items.removeAll { $0.id == bookmark.id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            items = try JSONDecoder().decode([Bookmark].self, from: data)
        } catch {
            // The next save() would overwrite a file we couldn't read, destroying the
            // user's phrasebook — set it aside for recovery instead.
            let backup = fileURL.appendingPathExtension("corrupt")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.moveItem(at: fileURL, to: backup)
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
