#if canImport(UIKit)
import SwiftUI
import NetInspectorCore
import UIKit

struct RequestDetailView: View {
    let entry: LogEntry
    @State private var tab: Tab = .overview

    enum Tab: String, CaseIterable, Identifiable {
        case overview = "Overview", headers = "Headers", body = "Body", timing = "Timing"
        var id: String { rawValue }
    }

    var body: some View {
        VStack {
            Picker("", selection: $tab) {
                ForEach(Tab.allCases) { t in Text(t.rawValue).tag(t) }
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollView {
                switch tab {
                case .overview: Overview()
                case .headers: Headers()
                case .body: BodyView()
                case .timing: Timing()
                }
            }
        }
        .navigationTitle(entry.request.url.path.isEmpty ? "/" : entry.request.url.path)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func Overview() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(entry.request.method).bold()
                if let code = entry.response?.statusCode {
                    Label("\(code)", systemImage: "number")
                } else if entry.response?.errorDescription != nil {
                    Label("Error", systemImage: "exclamationmark.triangle.fill")
                }
            }
            .font(.title3)

            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    Row("Capture Source", value: entry.source.rawValue)
                    Row("Timestamp", value: DateFormatter.localizedString(from: entry.timestamp, dateStyle: .none, timeStyle: .medium))
                    let fullURL = reconstructURL(from: entry.request.url)
                    Row("Full URL", value: fullURL)
                }
            }

            if entry.flags.isRedacted {
                Label("REDACTED FIELDS", systemImage: "lock.fill").foregroundColor(.purple)
            }
            if entry.flags.isTruncated {
                Label("TRUNCATED", systemImage: "exclamationmark.triangle.fill").foregroundColor(.orange)
            }

            if let d = entry.diagnostics {
                GroupBox {
                    VStack(alignment: .leading, spacing: 6) {
                        Row("Classification", value: d.classification.rawValue)
                        ForEach(d.issues, id: \.code) { issue in
                            Row(issue.code, value: issue.message)
                        }
                    }
                } label: {
                    Text("Diagnostics")
                }
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    Row("Sent", value: formatBytes(Int(entry.request.body?.preview.data(using: .utf8)?.count ?? 0)))
                    Row("Received", value: formatBytes(Int(entry.response?.body?.preview.data(using: .utf8)?.count ?? 0)))
                }
            } label: {
                Text("Sizes")
            }
        }
        .padding()
    }

    @ViewBuilder private func Headers() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                ForEach(entry.request.headers, id: \.name) { h in
                    CopyRow(title: h.name, value: h.value)
                }
            } label: { Text("Request Headers") }

            if let res = entry.response {
                GroupBox {
                    ForEach(res.headers, id: \.name) { h in
                        CopyRow(title: h.name, value: h.value)
                    }
                } label: { Text("Response Headers") }
            }
        }
        .padding()
    }

    @ViewBuilder private func BodyView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.request.body?.contentTypeHint ?? "Body").font(.caption).foregroundColor(.secondary)
                    ScrollView(.horizontal) {
                        Text(entry.request.body?.preview ?? "No body content").textSelection(.enabled)
                            .font(.system(.body, design: .monospaced))
                    }
                    HStack {
                        Spacer()
                        Button("Copy") { UIPasteboard.general.string = entry.request.body?.preview }
                            .buttonStyle(.bordered)
                    }
                }
            } label: { Text("Request") }

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.response?.body?.contentTypeHint ?? "Body").font(.caption).foregroundColor(.secondary)
                    ScrollView(.horizontal) {
                        Text(entry.response?.body?.preview ?? "No body content").textSelection(.enabled)
                            .font(.system(.body, design: .monospaced))
                    }
                    HStack {
                        Spacer()
                        Button("Copy") { UIPasteboard.general.string = entry.response?.body?.preview }
                            .buttonStyle(.bordered)
                    }
                }
            } label: { Text("Response") }
        }
        .padding()
    }

    @ViewBuilder private func Timing() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    Row("Total request duration", value: durationText(entry.metrics?.duration))
                    Row("Started", value: timeText(entry.metrics?.startedAt))
                    Row("Ended", value: timeText(entry.metrics?.endedAt))
                }
            }
        }
        .padding()
    }

    private func Row(_ title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }

    private func CopyRow(title: String, value: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title).font(.caption).foregroundColor(.secondary)
                Text(value).textSelection(.enabled)
            }
            Spacer()
            Button("Copy") { UIPasteboard.general.string = value }
                .buttonStyle(.bordered)
        }
    }

    private func durationText(_ t: TimeInterval?) -> String {
        guard let t else { return "—" }
        return String(format: "%.2fs", t)
    }

    private func timeText(_ d: Date?) -> String {
        guard let d else { return "—" }
        return DateFormatter.localizedString(from: d, dateStyle: .none, timeStyle: .medium)
    }

    private func formatBytes(_ n: Int) -> String {
        if n < 1024 { return "\(n) B" }
        let kb = Double(n) / 1024.0
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        return String(format: "%.1f MB", kb / 1024.0)
    }

    private func reconstructURL(from comps: URLComponentsLog) -> String {
        var u = URLComponents()
        u.scheme = comps.scheme
        u.host = comps.host
        u.percentEncodedPath = comps.path
        u.percentEncodedQuery = comps.query
        return u.string ?? comps.path
    }
}
#endif