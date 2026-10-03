import Foundation
import NetInspectorCore

public struct CurlExporter {
    public init() {}

    public func export(entry: LogEntry) -> String {
        let req = entry.request
        let method = req.method.uppercased()
        let url = reconstructURL(from: req.url)

        var parts: [String] = ["curl"]

        parts.append("-X \(shellEscape(method))")

        for h in req.headers {
            parts.append("-H \(shellEscape("\(h.name): \(h.value)"))")
        }

        if let body = req.body, body.isTruncated == false, let data = body.preview.data(using: .utf8), data.count > 0 {
            parts.append("--data-binary \(shellEscape(body.preview))")
        }

        parts.append(shellEscape(url))
        return parts.joined(separator: " ")
    }

    private func reconstructURL(from comps: URLComponentsLog) -> String {
        var u = URLComponents()
        u.scheme = comps.scheme
        u.host = comps.host
        u.percentEncodedPath = comps.path
        u.percentEncodedQuery = comps.query
        return u.string ?? (comps.path)
    }

    private func shellEscape(_ s: String) -> String {
        "'\(s.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}