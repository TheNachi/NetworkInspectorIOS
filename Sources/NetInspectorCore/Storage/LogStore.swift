import Foundation

public actor LogStore {
    private var entries: [LogEntry] = []
    private var maxEntries: Int

    public init(maxEntries: Int) {
        self.maxEntries = maxEntries
    }

    public func updateCapacity(_ max: Int) {
        maxEntries = max
        enforceCapacity()
    }

    public func insert(_ entry: LogEntry) {
        entries.append(entry)
        enforceCapacity()
    }

    public func allEntries() -> [LogEntry] {
        entries
    }

    public func clear() {
        entries.removeAll()
    }

    private func enforceCapacity() {
        if entries.count > maxEntries {
            let overflow = entries.count - maxEntries
            if overflow > 0 && overflow <= entries.count {
                entries.removeFirst(overflow)
            }
        }
    }
}