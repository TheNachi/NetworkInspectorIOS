#if os(iOS)
import SwiftUI
import UIKit
import NetInspectorCore

struct ExportView: View {
    enum Format: String, CaseIterable, Identifiable { case curl = "cURL", json = "JSON"; var id: String { rawValue } }

    @State private var format: Format = .json
    @State private var scopeErrorsOnly = false
    @State private var exportText: String = ""
    @State private var exportInfo: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Format") {
                    Picker("Format", selection: $format) {
                        ForEach(Format.allCases) { f in Text(f.rawValue).tag(f) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Scope") {
                    Toggle("Errors Only", isOn: $scopeErrorsOnly)
                }

                Section("Export") {
                    Button("Generate") { Task { await generate() } }
                    if !exportText.isEmpty {
                        Button("Copy to Clipboard") {
                            UIPasteboard.general.string = exportText
                            exportInfo = "Copied"
                        }
                    }
                    if !exportInfo.isEmpty {
                        Text(exportInfo).font(.footnote).foregroundColor(.secondary)
                    }
                }

                if !exportText.isEmpty {
                    Section("Preview") {
                        ScrollView {
                            Text(exportText)
                                .textSelection(.enabled)
                                .font(.system(.footnote, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(minHeight: 200)
                    }
                }

                Section("Privacy") {
                    Text("The SDK privacy pipeline redacts sensitive headers and JSON fields before storage. Exported data inherits these redactions automatically.")
                        .font(.footnote)
                }
            }
            .navigationTitle("Export")
        }
    }

    private func generate() async {
        let all = await NetworkInspector.entries()
        let items = scopeErrorsOnly ? all.filter { ($0.response?.statusCode ?? 0) >= 400 || $0.response?.errorDescription != nil } : all

        switch format {
        case .json:
            do {
                let data = try NetworkInspector.exportJSON(entries: items)
                exportText = String(data: data, encoding: .utf8) ?? ""
                exportInfo = "JSON created"
            } catch {
                exportText = ""
                exportInfo = "Failed to create JSON: \(error.localizedDescription)"
            }
        case .curl:
            if let first = items.first {
                exportText = NetworkInspector.exportCurl(entry: first)
                exportInfo = "cURL generated for first selected request"
            } else {
                exportText = ""
                exportInfo = "No request available"
            }
        }
    }
}
#endif