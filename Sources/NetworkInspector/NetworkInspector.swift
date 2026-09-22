import Foundation
import NetInspectorCore
import NetInspectorURLSession

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

    public static func enable() {
        Task.detached {
            guard let rt = await RuntimeRegistry.shared.runtimeInstance() else { return }
            var cfg = await rt.configurationStore.current()
            cfg.enabledByDefault = true
            await rt.configurationStore.update(cfg)
        }
    }

    public static func disable() {
        Task.detached {
            guard let rt = await RuntimeRegistry.shared.runtimeInstance() else { return }
            var cfg = await rt.configurationStore.current()
            cfg.enabledByDefault = false
            await rt.configurationStore.update(cfg)
        }
    }

    public static func makeInstrumentedSession(configuration: URLSessionConfiguration) -> URLSession {
        NetInspectorURLSession.makeInstrumentedSession(configuration: configuration)
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

    public static func pause() {
        Task.detached {
            guard let rt = await RuntimeRegistry.shared.runtimeInstance() else { return }
            await rt.configurationStore.pause()
        }
    }

    public static func resume() {
        Task.detached {
            guard let rt = await RuntimeRegistry.shared.runtimeInstance() else { return }
            await rt.configurationStore.resume()
        }
    }

    public static func withLoggingDisabled<T>(_ operation: @escaping @Sendable () async throws -> T) async rethrows -> T {
        if let rt = await RuntimeRegistry.shared.runtimeInstance() {
            return try await rt.configurationStore.withLoggingDisabled(operation: operation)
        } else {
            return try await operation()
        }
    }
}