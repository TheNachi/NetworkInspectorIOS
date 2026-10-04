import Foundation
#if canImport(NetInspectorCore)
import NetInspectorCore
#endif

public struct JSONExporter {
    public init() {}

    public func export(entries: [LogEntry]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(entries)
    }
}