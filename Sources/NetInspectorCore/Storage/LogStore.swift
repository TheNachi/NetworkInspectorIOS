import Foundation

public actor LogStore {
    private var entries: [LogEntry] = []
    private var maxEntries: Int

    private var continuations: [UUID: AsyncStream<NetworkEvent>.Continuation] = [:]

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
        yield(.inserted(entry))
    }

    public func allEntries() -> [LogEntry] {
        entries
    }

    public func entry(id: UUID) -> LogEntry? {
        entries.first { $0.id == id }
    }

    public func update(id: UUID, to newEntry: LogEntry) {
        if let idx = entries.firstIndex(where: { $0.id == id }) {
            entries[idx] = newEntry
            yield(.updated(newEntry))
        }
    }

    public func clear() {
        entries.removeAll()
        yield(.cleared)
    }

    public func stream() -> AsyncStream<NetworkEvent> {
        let id = UUID()
        return AsyncStream { continuation in
            continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(id: id) }
            }
        }
    }

    private func removeContinuation(id: UUID) {
        continuations[id] = nil
    }

    private func yield(_ event: NetworkEvent) {
        for (_, c) in continuations {
            c.yield(event)
        }
    }

    private func enforceCapacity() {
        if entries.count > maxEntries {
            let overflow = entries.count - maxEntries
            if overflow > 0 && overflow <= entries.count {
                let removed = entries.prefix(overflow).map { $0.id }
                entries.removeFirst(overflow)
                for id in removed {
                    yield(.removed(id))
                }
            }
        }
    }
}