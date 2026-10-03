import SwiftUI
import NetInspectorCore

@MainActor
final class RequestsViewModel: ObservableObject {
    @Published var entries: [LogEntry] = []
    @Published var search: String = ""
    @Published var filterGroup: FilterGroup = .all

    private var task: Task<Void, Never>?

    enum FilterGroup: String, CaseIterable, Identifiable {
        case all = "All"
        case errors = "Errors"
        case s2xx = "2xx"
        case s4xx = "4xx"
        case s5xx = "5xx"

        var id: String { rawValue }
    }

    func start() {
        task?.cancel()
        task = Task {
            let snapshot = await NetworkInspector.entries()
            await MainActor.run { self.entries = snapshot }
            if let stream = await NetworkInspector.eventStream() {
                for await event in stream {
                    switch event {
                    case .inserted(let e):
                        entries.append(e)
                    case .updated(let e):
                        if let i = entries.firstIndex(where: { $0.id == e.id }) {
                            entries[i] = e
                        }
                    case .removed(let id):
                        entries.removeAll { $0.id == id }
                    case .cleared:
                        entries.removeAll()
                    }
                }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    var filtered: [LogEntry] {
        entries
            .filter { e in
                guard !search.isEmpty else { return true }
                let text = [
                    e.request.method,
                    e.request.url.host ?? "",
                    e.request.url.path,
                    e.request.url.query ?? ""
                ].joined(separator: " ").lowercased()
                return text.contains(search.lowercased())
            }
            .filter { e in
                switch filterGroup {
                case .all: return true
                case .errors:
                    if let c = e.response?.statusCode, c >= 400 { return true }
                    if e.response?.errorDescription != nil { return true }
                    return false
                case .s2xx:
                    if let c = e.response?.statusCode { return (200..<300).contains(c) }
                    return false
                case .s4xx:
                    if let c = e.response?.statusCode { return (400..<500).contains(c) }
                    return false
                case .s5xx:
                    if let c = e.response?.statusCode { return (500..<600).contains(c) }
                    return false
                }
            }
            .sorted { $0.timestamp > $1.timestamp }
    }
}

struct RequestsView: View {
    @StateObject private var vm = RequestsViewModel()

    var body: some View {
        NavigationStack {
            List {
                if vm.entries.isEmpty {
                    Section {
                        Text("No requests yet").foregroundColor(.secondary)
                        Text("Make a network request with URLSession or use NetworkInspector.log(...)").font(.footnote).foregroundColor(.secondary)
                    }
                } else {
                    ForEach(vm.filtered, id: \.id) { entry in
                        NavigationLink {
                            RequestDetailView(entry: entry)
                        } label: {
                            EntryRow(entry: entry)
                        }
                    }
                }
            }
            .searchable(text: $vm.search)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("", selection: $vm.filterGroup) {
                        ForEach(RequestsViewModel.FilterGroup.allCases) { g in
                            Text(g.rawValue).tag(g)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 360)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        NetworkInspector.clear()
                    }
                }
            }
            .navigationTitle("Network Inspector")
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }
}

private struct EntryRow: View {
    let entry: LogEntry

    var statusText: String {
        if let c = entry.response?.statusCode { return "\(c)" }
        if entry.response?.errorDescription != nil { return "ERR" }
        return "—"
    }

    var durationText: String {
        if let d = entry.metrics?.duration { return String(format: "%.0fms", d * 1000) }
        return "—"
    }

    var sizeText: String {
        let down = entry.response?.body?.isTruncated == true ? "…" : ""
        let bytes = entry.response?.body?.preview.data(using: .utf8)?.count ?? 0
        return "\(formatBytes(bytes))\(down)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.request.method)
                    .font(.caption).bold()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(4)
                Text(entry.request.url.path.isEmpty ? "/" : entry.request.url.path)
                    .font(.body).bold()
                Spacer()
                Text(statusText)
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 12) {
                Text(entry.request.url.host ?? "")
                Text("• \(durationText)")
                Text("• \(sizeText)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            if entry.flags.isRedacted {
                Label("REDACTED", systemImage: "lock.fill").font(.caption2).foregroundColor(.purple)
            } else if entry.flags.isTruncated {
                Label("TRUNCATED", systemImage: "exclamationmark.triangle.fill").font(.caption2).foregroundColor(.orange)
            }
        }
    }

    private func formatBytes(_ n: Int) -> String {
        if n < 1024 { return "\(n) B" }
        let kb = Double(n) / 1024.0
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        return String(format: "%.1f MB", kb / 1024.0)
    }
}