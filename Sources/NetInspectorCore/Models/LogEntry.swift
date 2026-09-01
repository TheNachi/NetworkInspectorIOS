import Foundation

public struct RequestLog: Codable, Sendable, Hashable {
    public let method: String
    public let url: URLComponentsLog
    public let headers: [Header]
    public let body: BodySample?
    public let bodySize: Int64?

    public init(method: String, url: URL, headers: [Header], body: BodySample?, bodySize: Int64?) {
        self.method = method
        self.url = URLComponentsLog(url: url)
        self.headers = headers
        self.body = body
        self.bodySize = bodySize
    }
}

public struct ResponseLog: Codable, Sendable, Hashable {
    public let statusCode: Int?
    public let headers: [Header]
    public let body: BodySample?
    public let bodySize: Int64?
    public let errorDescription: String?

    public init(statusCode: Int?, headers: [Header], body: BodySample?, bodySize: Int64?, errorDescription: String?) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
        self.bodySize = bodySize
        self.errorDescription = errorDescription
    }
}

public struct LogFlags: Codable, Sendable, Hashable {
    public let isRedacted: Bool
    public let isTruncated: Bool
    public let isUpload: Bool
    public let isDownload: Bool

    public init(isRedacted: Bool = false, isTruncated: Bool = false, isUpload: Bool = false, isDownload: Bool = false) {
        self.isRedacted = isRedacted
        self.isTruncated = isTruncated
        self.isUpload = isUpload
        self.isDownload = isDownload
    }
}

public struct LogEntry: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let timestamp: Date
    public let source: NetworkSource
    public let request: RequestLog
    public let response: ResponseLog?
    public let metrics: NetworkMetrics?
    public let flags: LogFlags
    public let tags: [String: String]

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        source: NetworkSource,
        request: RequestLog,
        response: ResponseLog?,
        metrics: NetworkMetrics?,
        flags: LogFlags = .init(),
        tags: [String: String] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.request = request
        self.response = response
        self.metrics = metrics
        self.flags = flags
        self.tags = tags
    }
}