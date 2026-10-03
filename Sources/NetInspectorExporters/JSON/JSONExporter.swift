import Foundation
import NetInspectorCore

public struct JSONExporter {
    public init() {}

    public func export(entries: [LogEntry]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(entries)
    }
}