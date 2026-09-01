import Foundation

public struct RawRequestCapture: Sendable, Hashable {
    public let method: String
    public let url: URL
    public let headers: [String: String]
    public let body: Data?
    public let tags: [String: String]

    public init(method: String, url: URL, headers: [String: String], body: Data?, tags: [String: String] = [:]) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.tags = tags
    }
}

public struct RawResponseCapture: Sendable, Hashable {
    public let statusCode: Int?
    public let headers: [String: String]
    public let body: Data?

    public init(statusCode: Int?, headers: [String: String], body: Data?) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
}

public struct CapturedError: Sendable, Hashable {
    public let description: String

    public init(_ description: String) {
        self.description = description
    }
}

public struct CaptureEvent: Sendable, Hashable {
    public let id: UUID
    public let timestamp: Date
    public let source: NetworkSource
    public let request: RawRequestCapture
    public let response: RawResponseCapture?
    public let error: CapturedError?
    public let metrics: NetworkMetrics?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        source: NetworkSource,
        request: RawRequestCapture,
        response: RawResponseCapture? = nil,
        error: CapturedError? = nil,
        metrics: NetworkMetrics? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.request = request
        self.response = response
        self.error = error
        self.metrics = metrics
    }
}