import SwiftUI
import NetInspectorCore

@available(macOS 12.0, *)
public struct NetworkInspectorView: View {
    public init() {}

    public var body: some View {
        TabView {
            RequestsView()
                .tabItem {
                    Label("Requests", systemImage: "dot.circle")
                }

            ExportView()
                .tabItem {
                    Label("Export", systemImage: "arrow.up.square")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}