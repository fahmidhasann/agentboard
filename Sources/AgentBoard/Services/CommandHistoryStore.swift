import Foundation

final class CommandHistoryStore {
    static let shared = CommandHistoryStore()

    private var entries: [String: Int] = [:]
    private let maxEntries = 1000
    private let file: URL
    private var saveWorkItem: DispatchWorkItem?

    init(file: URL = AppPaths.appSupportDirectory.appendingPathComponent("command_history.json")) {
        self.file = file
        load()
    }

    func record(_ command: String) {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }
        entries[trimmed, default: 0] += 1
        evictIfNeeded()
        scheduleSave()
    }

    func suggestions(forPrefix prefix: String, limit: Int = 5) -> [String] {
        guard prefix.count >= 2 else { return [] }
        let lower = prefix.lowercased()
        return entries
            .filter { $0.key.lowercased().hasPrefix(lower) && $0.key != prefix }
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }

    private func evictIfNeeded() {
        guard entries.count > maxEntries else { return }
        let sorted = entries.sorted { $0.value < $1.value }
        let toRemove = entries.count - maxEntries
        for entry in sorted.prefix(toRemove) {
            entries.removeValue(forKey: entry.key)
        }
    }

    // MARK: - Persistence

    private func scheduleSave() {
        saveWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.saveNow() }
        saveWorkItem = item
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 2.0, execute: item)
    }

    func saveNow() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: file, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: file),
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else { return }
        entries = decoded
    }
}
