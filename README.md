# NetworkInspector (iOS)

An open-source network debugging and diagnostics SDK for iOS apps.

- Capture URLSession traffic (including async/await)
- Redact sensitive headers and JSON fields before storage
- Truncate large bodies (64 KB default), skip binary by default
- Inspect requests/responses in-app via SwiftUI inspector
- Export JSON and cURL (sanitized)
- Bounded in-memory storage, safe-by-default in Release

Status: V1.0 core complete

## Getting Started

1) Add the package (SPM)
- In Xcode: File → Add Packages → point at your repo URL (or local path).
- Minimum iOS 16, Swift 5.9.

2) Install and present

import NetworkInspector

@main
struct AppMain: App {
    init() {
        _ = NetworkInspector.install()   // Debug: enabled; Release: disabled by default
    }
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @State private var showing = false
    var body: some View {
        VStack {
            Button("Open Inspector") { showing = true }
        }
        .sheet(isPresented: $showing) {
            NetworkInspectorView()
        }
    }
}

3) Use an instrumented URLSession

let session = NetworkInspector.makeInstrumentedSession(configuration: .default)
let (data, response) = try await session.data(from: URL(string: "https://httpbin.org/get")!)

4) Manual capture (optional)

NetworkInspector.log(
    request: RequestLike(method: "GET", url: URL(string: "https://example.com")!),
    source: .manual
)

## Configuration

- Safe-by-default: disabled in Release builds unless you explicitly enable.
- Pause/resume or scoped suppression:

NetworkInspector.pause()
NetworkInspector.resume()
await NetworkInspector.withLoggingDisabled { /* sensitive ops */ }

## Export

- JSON: `try NetworkInspector.exportJSON(entries: await NetworkInspector.entries())`
- cURL: `NetworkInspector.exportCurl(entry: (await NetworkInspector.entries()).first!)`

## Privacy

- Default redaction: Authorization, Cookie, Set-Cookie, X-API-Key, X-Auth-Token, Proxy-Authorization
- Default JSON redaction: password, otp, .*token.*
- Redaction happens before storage and export.

## Roadmap

- V1.5: URLSessionTaskMetrics waterfall, HAR 1.2, advanced filters, disk persistence.
- V2.0: Alamofire, Moya, Apollo integrations.

License: MIT