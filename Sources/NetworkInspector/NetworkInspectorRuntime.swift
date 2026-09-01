import Foundation
import NetInspectorCore

struct NetworkInspectorRuntime {
    let configurationStore: ConfigurationStore
    let logStore: LogStore
    let captureCoordinator: CaptureCoordinator

    init(configuration: Configuration) {
        self.configurationStore = ConfigurationStore(configuration: configuration)
        self.logStore = LogStore(maxEntries: configuration.maxEntries)
        self.captureCoordinator = CaptureCoordinator(configurationStore: configurationStore, logStore: logStore)
    }
}