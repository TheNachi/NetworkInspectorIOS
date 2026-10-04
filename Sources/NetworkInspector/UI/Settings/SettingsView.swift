#if canImport(UIKit)
import SwiftUI
import NetInspectorCore

struct SettingsView: View {
    @State private var enabled = true
    @State private var includeMetrics = true
    @State private var maxEntries = 500
    @State private var maxBodyKB = 64
    @State private var redactHeaders = true
    @State private var redactJSON = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Capturing URLSession network traffic", systemImage: "dot.radiowaves.left.and.right")
                        .foregroundColor(.green)
                }

                Section("Capture") {
                    Toggle("Inspector Enabled", isOn: $enabled)
                        .onChange(of: enabled) { new in
                            Task { await updateConfig { $0.enabledByDefault = new } }
                        }
                    Toggle("Task Metrics", isOn: $includeMetrics)
                        .onChange(of: includeMetrics) { new in
                            Task { await updateConfig { $0.includeTaskMetrics = new } }
                        }
                    Stepper(value: $maxEntries, in: 50...10_000, step: 50) {
                        HStack {
                            Text("Max Entries")
                            Spacer()
                            Text("\(maxEntries)")
                        }
                    }
                    .onChange(of: maxEntries) { new in
                        Task { await updateConfig { $0.maxEntries = new } }
                    }
                    Stepper(value: $maxBodyKB, in: 1...1024, step: 1) {
                        HStack {
                            Text("Max Body Size")
                            Spacer()
                            Text("\(maxBodyKB) KB per request")
                        }
                    }
                    .onChange(of: maxBodyKB) { new in
                        Task { await updateConfig { $0.maxBodyBytes = new * 1024 } }
                    }
                }

                Section("Privacy Pipeline") {
                    Toggle("Redact Auth Headers", isOn: $redactHeaders)
                        .onChange(of: redactHeaders) { new in
                            Task {
                                await updateConfig {
                                    $0.redactHeaders = new ? ["authorization", "cookie", "set-cookie", "x-api-key", "x-auth-token", "proxy-authorization"] : []
                                }
                            }
                        }
                    Toggle("Redact JSON Fields", isOn: $redactJSON)
                        .onChange(of: redactJSON) { new in
                            Task {
                                await updateConfig {
                                    $0.redactBodyKeys = new ? [
                                        .init(.exact("password")),
                                        .init(.exact("otp")),
                                        .init(.regex(".*token.*"))
                                    ] : []
                                }
                            }
                        }
                }

                Section("V1.0 Capture Sources") {
                    HStack {
                        Text("URLSession")
                        Spacer()
                        Label("Fully Supported", systemImage: "checkmark").foregroundColor(.green)
                    }
                    HStack {
                        Text("Async/Await")
                        Spacer()
                        Label("Fully Supported", systemImage: "checkmark").foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Settings")
            .task { await loadCurrentConfig() }
        }
    }

    private func loadCurrentConfig() async {
        if let rt = await RuntimeRegistry.shared.runtimeInstance() {
            let cfg = await rt.configurationStore.current()
            enabled = cfg.enabledByDefault
            includeMetrics = cfg.includeTaskMetrics
            maxEntries = cfg.maxEntries
            maxBodyKB = max(1, cfg.maxBodyBytes / 1024)
            redactHeaders = !cfg.redactHeaders.isEmpty
            redactJSON = !cfg.redactBodyKeys.isEmpty
        }
    }

    private func updateConfig(_ change: @escaping (inout Configuration) -> Void) async {
        if let rt = await RuntimeRegistry.shared.runtimeInstance() {
            var cfg = await rt.configurationStore.current()
            change(&cfg)
            await rt.configurationStore.update(cfg)
            await rt.logStore.updateCapacity(cfg.maxEntries)
        }
    }
}
#endif