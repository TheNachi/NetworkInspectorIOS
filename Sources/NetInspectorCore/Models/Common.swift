import Foundation

public enum NetworkSource: String, Codable, Sendable, Hashable {
    case urlsession, alamofire, moya, apollo, web, manual
}

public struct Header: Codable, Sendable, Hashable {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

public struct URLComponentsLog: Codable, Sendable, Hashable {
    public let scheme: String?
    public let host: String?
    public let path: String
    public let query: String?

    public init(url: URL) {
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        self.scheme = comps?.scheme
        self.host = comps?.host
        self.path = comps?.percentEncodedPath ?? url.path
        self.query = comps?.percentEncodedQuery
    }
}

public struct BodySample: Codable, Sendable, Hashable {
    public let preview: String
    public let isTruncated: Bool
    public let isRedacted: Bool
    public let contentTypeHint: String?

    public init(preview: String, isTruncated: Bool, isRedacted: Bool, contentTypeHint: String? = nil) {
        self.preview = preview
        self.isTruncated = isTruncated
        self.isRedacted = isRedacted
        self.contentTypeHint = contentTypeHint
    }
}

public struct RequestLike: Sendable, Hashable {
    public let method: String
    public let url: URL
    public let headers: [String: String]
    public let body: Data?
    public let tags: [String: String]

    public init(method: String, url: URL, headers: [String: String] = [:], body: Data? = nil, tags: [String: String] = [:]) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.tags = tags
    }
}

public struct ResponseLike: Sendable, Hashable {
    public let statusCode: Int?
    public let headers: [String: String]
    public let body: Data?

    public init(statusCode: Int?, headers: [String: String] = [:], body: Data? = nil) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
}

public struct NetworkMetrics: Codable, Sendable, Hashable {
    public let startedAt: Date?
    public let endedAt: Date?
    public let duration: TimeInterval?
    public let dnsDuration: TimeInterval?
    public let connectionDuration: TimeInterval?
    public let tlsDuration: TimeInterval?
    public let requestDuration: TimeInterval?
    public let responseDuration: TimeInterval?

    public init(
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        duration: TimeInterval? = nil,
        dnsDuration: TimeInterval? = nil,
        connectionDuration: TimeInterval? = nil,
        tlsDuration: TimeInterval? = nil,
        requestDuration: TimeInterval? = nil,
        responseDuration: TimeInterval? = nil
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.duration = duration
        self.dnsDuration = dnsDuration
        self.connectionDuration = connectionDuration
        self.tlsDuration = tlsDuration
        self.requestDuration = requestDuration
        self.responseDuration = responseDuration
    }
}