import Foundation
#if canImport(NetInspectorCore)
import NetInspectorCore
#endif
#if canImport(NetInspectorURLSession)
import NetInspectorURLSession
#endif
#if canImport(NetInspectorExporters)
import NetInspectorExporters
#endif

public enum NetworkInspector {

    @discardableResult
    public static func install(configuration: Configuration = .default) -> Bool {
        let sema = DispatchSemaphore(value: 0)
        Task {
            await RuntimeRegistry.shared.install(configuration: configuration)
            sema.signal()
        }
        sema.wait()
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

    public static func eventStream() async -> AsyncStream<NetworkEvent>? {
        await RuntimeRegistry.shared.eventStream()
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

    public static func exportJSON(entries: [LogEntry]) throws -> Data {
        try JSONExporter().export(entries: entries)
    }

    public static func exportCurl(entry: LogEntry) -> String {
        CurlExporter().export(entry: entry)
    }

    public static func log(
        request: RequestLike,
        response: ResponseLike? = nil,
        error: Error? = nil,
        metrics: NetworkMetrics? = nil,
        source: NetworkSource = .manual
    ) {
        let sema = DispatchSemaphore(value: 0)
        Task {
            guard let rt = await RuntimeRegistry.shared.runtimeInstance() else {
                sema.signal()
                return
            }

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
            sema.signal()
        }
        sema.wait()
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