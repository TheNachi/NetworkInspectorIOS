import Foundation
import NetInspectorCore
import NetInspectorDiagnostics

actor RuntimeRegistry {
    static let shared = RuntimeRegistry()

    private var runtime: NetworkInspectorRuntime?

    func install(configuration: Configuration) {
        runtime = NetworkInspectorRuntime(configuration: configuration)

        if let runtime {
            Task.detached {
                await GlobalCaptureRouter.shared.register { event in
                    await runtime.captureCoordinator.process(event)
                    if let stored = await runtime.logStore.entry(id: event.id) {
                        let engine = DiagnosticsEngine()
                        let diags = engine.classify(entry: stored)
                        let factory = LogEntryFactory()
                        let updated = factory.withDiagnostics(stored, diagnostics: diags)
                        await runtime.logStore.update(id: stored.id, to: updated)
                    }
                }
            }
        }
    }

    func isInstalled() -> Bool {
        runtime != nil
    }

    func updateConfiguration(_ configuration: Configuration) async {
        guard let runtime else { return }
        await runtime.configurationStore.update(configuration)
        await runtime.logStore.updateCapacity(configuration.maxEntries)
    }

    func runtimeInstance() -> NetworkInspectorRuntime? {
        runtime
    }

    func clear() async {
        guard let runtime else { return }
        await runtime.logStore.clear()
    }

    func eventStream() async -> AsyncStream<NetworkEvent>? {
        guard let runtime else { return nil }
        return await runtime.logStore.stream()
    }
}