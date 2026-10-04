#if canImport(UIKit)
import SwiftUI
#if canImport(NetInspectorCore)
import NetInspectorCore
#endif

public struct NetworkInspectorView: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView {
                RequestsView()
                    .tabItem { Label("Requests", systemImage: "dot.circle") }

                ExportView()
                    .tabItem { Label("Export", systemImage: "arrow.up.square") }

                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape") }
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
                    .shadow(radius: 1)
            }
            .padding(.top, 8)
            .padding(.trailing, 12)
        }
    }
}
#endif