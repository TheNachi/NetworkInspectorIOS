#if canImport(UIKit)
import SwiftUI
#if canImport(NetInspectorCore)
import NetInspectorCore
#endif
import UIKit

struct RequestDetailView: View {
    let entry: LogEntry
    @State private var tab: Tab = .overview
    @Environment(\.dismiss) private var dismiss

    enum Tab: String, CaseIterable, Identifiable {
        case overview = "Overview", headers = "Headers", body = "Body", timing = "Timing"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // Header actions (cURL / Open)
                HStack {
                    Spacer()
                    Button {
                        let curl = NetworkInspector.exportCurl(entry: entry)
                        UIPasteboard.general.string = curl
                    } label: {
                        Text("cURL")
                            .font(.subheadline).bold()
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Capsule())
                    }
                    Button {
                        if let url = reconstructedURL() {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Segmented tabs
                Picker("", selection: $tab) {
                    ForEach(Tab.allCases) { t in Text(t.rawValue).tag(t) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        switch tab {
                        case .overview: Overview()
                        case .headers: Headers()
                        case .body: BodyView()
                        case .timing: Timing()
                        }
                    }
                    .padding(16)
                }
            }

            // Close button (dismiss sheet from detail)
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
        .navigationTitle(entry.request.url.path.isEmpty ? "/" : entry.request.url.path)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func Overview() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(entry.request.method).bold()
                        if let code = entry.response?.statusCode {
                            Text("\(code)").font(.headline)
                        } else if entry.response?.errorDescription != nil {
                            Text("Error").font(.headline)
                        }
                        Spacer()
                    }

                    Row("Capture Source", value: entry.source.rawValue)
                    Row("Timestamp", value: DateFormatter.localizedString(from: entry.timestamp, dateStyle: .none, timeStyle: .medium))
                    Row("Full URL", value: reconstructedURL()?.absoluteString ?? reconstructURLString(from: entry.request.url))
                }
            }

            if entry.flags.isRedacted {
                Label("REDACTED FIELDS", systemImage: "lock.fill")
                    .foregroundColor(.purple)
            }

            if let d = entry.diagnostics {
                GroupBox {
                    VStack(alignment: .leading, spacing: 6) {
                        Row("Classification", value: d.classification.rawValue)
                        ForEach(d.issues, id: \.code) { issue in
                            Row(issue.code, value: issue.message)
                        }
                    }
                } label: { Text("Diagnostics") }
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    Row("Sent", value: formatBytes(Int(entry.request.body?.preview.data(using: .utf8)?.count ?? 0)))
                    Row("Received", value: formatBytes(Int(entry.response?.body?.preview.data(using: .utf8)?.count ?? 0)))
                }
            } label: { Text("Sizes") }
        }
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
    }

    @ViewBuilder private func BodyView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.request.body?.contentTypeHint ?? "Body").font(.caption).foregroundColor(.secondary)
                    ScrollView(.horizontal) {
                        Text(entry.request.body?.preview ?? "No body content")
                            .textSelection(.enabled)
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
                        Text(entry.response?.body?.preview ?? "No body content")
                            .textSelection(.enabled)
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
    }

    @ViewBuilder private func Timing() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    let total = entry.metrics?.duration ?? 0
                    Text(String(format: "%.2fs", total))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                    Text("Total request duration").foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    Row("Started", value: timeText(entry.metrics?.startedAt))
                    Row("Ended", value: timeText(entry.metrics?.endedAt))
                }
            } label: { Text("Connection") }
        }
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

    private func reconstructedURL() -> URL? {
        var u = URLComponents()
        u.scheme = entry.request.url.scheme
        u.host = entry.request.url.host
        u.percentEncodedPath = entry.request.url.path
        u.percentEncodedQuery = entry.request.url.query
        return u.url
    }

    private func reconstructURLString(from comps: URLComponentsLog) -> String {
        var u = URLComponents()
        u.scheme = comps.scheme
        u.host = comps.host
        u.percentEncodedPath = comps.path
        u.percentEncodedQuery = comps.query
        return u.string ?? comps.path
    }
}
#endif