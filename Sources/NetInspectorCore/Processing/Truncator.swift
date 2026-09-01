import Foundation

public struct BodyTruncator: Sendable {
    public init() {}

    public func makeBodySample(
        data: Data?,
        headers: [Header],
        maxBytes: Int,
        captureBinary: Bool,
        isRedacted: Bool
    ) -> BodySample? {
        guard let data else { return nil }

        let contentType = headers.first { $0.name.caseInsensitiveCompare("Content-Type") == .orderedSame }?.value
        let mime = contentType ?? ""

        if isLikelyBinary(mime: mime, data: data), captureBinary == false {
            return nil
        }

        let truncated = data.count > maxBytes
        let slice = truncated ? data.prefix(maxBytes) : data

        if isTextual(mime: mime) || String(data: slice, encoding: .utf8) != nil {
            let text = String(data: slice, encoding: .utf8) ?? "<non-utf8>"
            return BodySample(preview: text, isTruncated: truncated, isRedacted: isRedacted, contentTypeHint: mime.isEmpty ? nil : mime)
        } else {
            let desc = "binary(\(slice.count) bytes)"
            return BodySample(preview: desc, isTruncated: truncated, isRedacted: isRedacted, contentTypeHint: mime.isEmpty ? "application/octet-stream" : mime)
        }
    }

    private func isTextual(mime: String) -> Bool {
        if mime.lowercased().hasPrefix("text/") { return true }
        let textual = ["application/json", "application/xml", "application/x-www-form-urlencoded"]
        return textual.contains { mime.lowercased().hasPrefix($0) }
    }

    private func isLikelyBinary(mime: String, data: Data) -> Bool {
        if mime.isEmpty { return data.contains(0) }
        if isTextual(mime: mime) { return false }
        return true
    }
}