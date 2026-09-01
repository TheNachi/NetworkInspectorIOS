import Foundation

public struct CaptureSampler: Sendable {
    public init() {}

    public func shouldSample(event: CaptureEvent, config: Configuration) -> Bool {
        switch config.sampling.kind {
        case .all:
            return true
        case .errorsOnly:
            if let code = event.response?.statusCode {
                return code >= 400
            }
            return event.error != nil
        case .percentage(let p):
            guard p > 0 else { return false }
            guard p < 1 else { return true }
            var hasher = Hasher()
            hasher.combine(event.id)
            let hash = hasher.finalize()
            let normalized = abs(Double(hash % 10_000)) / 10_000.0
            return normalized < p
        }
    }
}