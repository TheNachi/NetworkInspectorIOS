#if canImport(UIKit)
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
        case s2xx = "2xx"
        case s4xx = "4xx"
        case s5xx = "5xx"
        case errors = "Errors"

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
                case .s2xx:
                    if let c = e.response?.statusCode { return (200..<300).contains(c) }
                    return false
                case .s4xx:
                    if let c = e.response?.statusCode { return (400..<500).contains(c) }
                    return false
                case .s5xx:
                    if let c = e.response?.statusCode { return (500..<600).contains(c) }
                    return false
                case .errors:
                    if let c = e.response?.statusCode, c >= 400 { return true }
                    if e.response?.errorDescription != nil { return true }
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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Title row with Clear pill to the right
                    HStack {
                        Text("Network Inspector")
                            .font(.largeTitle).bold()
                        Spacer()
                        Button(action: { NetworkInspector.clear() }) {
                            Text("Clear")
                                .font(.subheadline).bold()
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                        }
                    }

                    // SEARCH
                    SearchField(text: $vm.search)

                    // QUICK FILTERS (chips below search)
                    QuickFiltersRow(selection: $vm.filterGroup)

                    // LIST
                    if vm.entries.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No requests yet")
                                .foregroundColor(.secondary)
                            Text("Make a request with the instrumented URLSession or call NetworkInspector.log(...).")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 16)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(vm.filtered, id: \.id) { entry in
                                NavigationLink {
                                    RequestDetailView(entry: entry)
                                } label: {
                                    EntryRow(entry: entry)
                                        .padding(.vertical, 10)
                                        .padding(.trailing, 12)
                                }
                                .buttonStyle(.plain)

                                Divider()
                                    .padding(.leading, 12)
                            }
                        }
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }
}

// Search field styled like a bar
private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search URL, method, host…", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// Horizontal chip row: All, 2xx, 4xx, 5xx, Errors
private struct QuickFiltersRow: View {
    @Binding var selection: RequestsViewModel.FilterGroup

    private let items: [RequestsViewModel.FilterGroup] = [.all, .s2xx, .s4xx, .s5xx, .errors]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.id) { item in
                    Button {
                        selection = item
                    } label: {
                        Text(item.rawValue)
                            .font(.subheadline).fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(background(for: item))
                            .foregroundColor(foreground(for: item))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func background(for item: RequestsViewModel.FilterGroup) -> Color {
        selection == item ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground)
    }

    private func foreground(for item: RequestsViewModel.FilterGroup) -> Color {
        selection == item ? .accentColor : .primary
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
        HStack(spacing: 0) {
            Rectangle()
                .fill(statusColor())
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))

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
                    Label("REDACTED", systemImage: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.purple)
                } else if entry.flags.isTruncated {
                    Label("TRUNCATED", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 4)
        }
    }

    private func statusColor() -> Color {
        if let c = entry.response?.statusCode {
            if (200..<300).contains(c) { return .green }
            if (400..<500).contains(c) { return .orange }
            if (500..<600).contains(c) { return .red }
        }
        return Color(.separator)
    }

    private func formatBytes(_ n: Int) -> String {
        if n < 1024 { return "\(n) B" }
        let kb = Double(n) / 1024.0
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        return String(format: "%.1f MB", kb / 1024.0)
    }
}
#endif