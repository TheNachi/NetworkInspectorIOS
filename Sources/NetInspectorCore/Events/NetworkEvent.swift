import Foundation

public enum NetworkEvent: Sendable {
    case inserted(LogEntry)
    case updated(LogEntry)
    case removed(UUID)
    case cleared
}