import Foundation
import NetInspectorCore

public struct DiagnosticsEngine: Sendable {
    public init() {}

    public func classify(entry: LogEntry) -> NetworkDiagnostics {
        if let code = entry.response?.statusCode {
            switch code {
            case 200..<300: return .init(classification: .success)
            case 300..<400: return .init(classification: .redirect)
            case 400..<500: return .init(classification: .clientError)
            case 500..<600: return .init(classification: .serverError)
            default: break
            }
        }

        if let desc = entry.response?.errorDescription {
            if desc.localizedCaseInsensitiveContains("timed out") {
                return .init(classification: .timeout)
            }
            if desc.localizedCaseInsensitiveContains("cancelled") || desc.localizedCaseInsensitiveContains("canceled") {
                return .init(classification: .cancelled)
            }
            return .init(classification: .networkFailure)
        }

        return .init(classification: entry.response == nil ? .noResponse : .unknown)
    }
}