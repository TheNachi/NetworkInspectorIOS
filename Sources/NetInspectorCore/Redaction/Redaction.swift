import Foundation

public struct RedactionEngine: Sendable {
    public init() {}

    public func redactHeaders(_ headers: [Header], redactList: [String]) -> [Header] {
        let set = Set(redactList.map { $0.lowercased() })
        return headers.map { header in
            if set.contains(header.name.lowercased()) {
                return Header(name: header.name, value: "REDACTED")
            } else {
                return header
            }
        }
    }

    public func redactJSONBodyIfNeeded(_ data: Data?, rules: [JSONRedactionRule]) -> Data? {
        guard let data else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return data
        }
        let redacted = redactJSON(json, rules: rules)
        guard JSONSerialization.isValidJSONObject(redacted),
              let out = try? JSONSerialization.data(withJSONObject: redacted, options: [.withoutEscapingSlashes]) else {
            return data
        }
        return out
    }

    private func redactJSON(_ obj: Any, rules: [JSONRedactionRule]) -> Any {
        if let dict = obj as? [String: Any] {
            var out: [String: Any] = [:]
            for (k, v) in dict {
                if shouldRedact(key: k, rules: rules) {
                    out[k] = "REDACTED"
                } else {
                    out[k] = redactJSON(v, rules: rules)
                }
            }
            return out
        } else if let arr = obj as? [Any] {
            return arr.map { redactJSON($0, rules: rules) }
        } else {
            return obj
        }
    }

    private func shouldRedact(key: String, rules: [JSONRedactionRule]) -> Bool {
        for rule in rules {
            switch rule.kind {
            case .exact(let s):
                if key.caseInsensitiveCompare(s) == .orderedSame { return true }
            case .regex(let pattern):
                if let r = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                    let range = NSRange(location: 0, length: key.utf16.count)
                    if r.firstMatch(in: key, options: [], range: range) != nil {
                        return true
                    }
                }
            }
        }
        return false
    }
}