import Foundation

actor RuntimeRegistry {
    static let shared = RuntimeRegistry()

    private var runtime: NetworkInspectorRuntime?

    func install(configuration: Configuration) {
        if let _ = runtime {
            runtime = NetworkInspectorRuntime(configuration: configuration)
        } else {
            runtime = NetworkInspectorRuntime(configuration: configuration)
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
}