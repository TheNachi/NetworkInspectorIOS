import Foundation
import NetInspectorCore

public enum NetworkInspector {

    @discardableResult
    public static func install(configuration: Configuration = .default) -> Bool {
        Task.detached {
            await RuntimeRegistry.shared.install(configuration: configuration)
        }
        return true
    }

    public static func updateConfiguration(_ configuration: Configuration) {
        Task.detached {
            await RuntimeRegistry.shared.updateConfiguration(configuration)
        }
    }

    public static func isInstalled() async -> Bool {
        await RuntimeRegistry.shared.isInstalled()
    }

    public static func clear() {
        Task.detached {
            await RuntimeRegistry.shared.clear()
        }
    }

    public static func entries() async -> [LogEntry] {
        guard let rt = await RuntimeRegistry.shared.runtimeInstance() else { return [] }
        return await rt.logStore.allEntries()
    }

    public static func log(
        request: RequestLike,
        response: ResponseLike? = nil,
        error: Error? = nil,
        metrics: NetworkMetrics? = nil,
        source: NetworkSource = .manual
    ) {
        Task.detached {
            guard let rt = await RuntimeRegistry.shared.runtimeInstance() else { return }

            let event = CaptureEvent(
                source: source,
                request: RawRequestCapture(
                    method: request.method,
                    url: request.url,
                    headers: request.headers,
                    body: request.body,
                    tags: request.tags
                ),
                response: response.map { RawResponseCapture(statusCode: $0.statusCode, headers: $0.headers, body: $0.body) },
                error: error.map { CapturedError($0.localizedDescription) },
                metrics: metrics
            )

            await rt.captureCoordinator.process(event)
        }
    }
}