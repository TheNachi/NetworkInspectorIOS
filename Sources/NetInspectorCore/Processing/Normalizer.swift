import Foundation

public struct LogNormalizer: Sendable {
    public init() {}

    public func normalizeRequest(_ raw: RawRequestCapture) -> (headers: [Header], body: Data?, bodySize: Int64?) {
        let headers = raw.headers.map { Header(name: $0.key, value: $0.value) }
        let body = raw.body
        let size: Int64? = body.map { Int64($0.count) }
        return (headers, body, size)
    }

    public func normalizeResponse(_ raw: RawResponseCapture?) -> (headers: [Header], body: Data?, bodySize: Int64?)? {
        guard let raw else { return nil }
        let headers = raw.headers.map { Header(name: $0.key, value: $0.value) }
        let body = raw.body
        let size: Int64? = body.map { Int64($0.count) }
        return (headers, body, size)
    }
}