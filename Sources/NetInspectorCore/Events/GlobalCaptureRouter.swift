import Foundation

public actor GlobalCaptureRouter {
    public static let shared = GlobalCaptureRouter()

    private var sink: (@Sendable (CaptureEvent) async -> Void)?

    public func register(_ sink: @escaping @Sendable (CaptureEvent) async -> Void) {
        self.sink = sink
    }

    public func submit(_ event: CaptureEvent) async {
        if let sink {
            await sink(event)
        }
    }
}