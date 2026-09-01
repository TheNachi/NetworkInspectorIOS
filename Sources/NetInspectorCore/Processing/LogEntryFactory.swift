import Foundation

public struct LogEntryFactory: Sendable {
    public init() {}

    public func makeLogEntry(
        id: UUID,
        timestamp: Date,
        source: NetworkSource,
        request: RequestLog,
        response: ResponseLog?,
        metrics: NetworkMetrics?,
        flags: LogFlags,
        tags: [String: String]
    ) -> LogEntry {
        LogEntry(
            id: id,
            timestamp: timestamp,
            source: source,
            request: request,
            response: response,
            metrics: metrics,
            flags: flags,
            tags: tags
        )
    }
}