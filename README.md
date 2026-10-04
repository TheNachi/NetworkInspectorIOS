# NetworkInspector for iOS

NetworkInspector is an in-app network debugging SDK for inspecting and exporting HTTP traffic captured from an instrumented `URLSession`.

- Captures requests made through the SDK's instrumented `URLSession`, including async/await calls.
- Redacts configured headers and JSON fields before entries are stored.
- Limits captured body previews to 64 KB by default and skips likely binary bodies by default.
- Provides an embeddable SwiftUI inspector for requests, exports, and settings.
- Exports sanitized JSON and cURL.
- Keeps entries in bounded in-memory storage.
- Disables capture by default in Release builds.

Current package version: `1.0.0`.

## Requirements

- iOS 16.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Installation

### Swift Package Manager in Xcode

1. Choose **File > Add Package Dependencies**.
2. Enter the URL of this repository.
3. Select **Up to Next Major Version** and enter `1.0.0` as the starting version.
4. In the product list, add the `NetworkInspector` product to your app target.

### Package.swift

Add the package dependency and product to your app target. Replace the URL below with the repository's actual clone URL.

```swift
dependencies: [
	.package(url: "https://github.com/your-org/NetworkInspectorIOS.git", from: "1.0.0")
],
targets: [
	.target(
		name: "YourApp",
		dependencies: [
			.product(name: "NetworkInspector", package: "NetworkInspectorIOS")
		]
	)
]
```

## Quick Start: SwiftUI

Install the SDK once during app startup, then use an instrumented session for requests you want to capture.

```swift
import SwiftUI
import NetworkInspector

@main
struct YourApp: App {
	init() {
		_ = NetworkInspector.install()
	}

	var body: some Scene {
		WindowGroup {
			ContentView()
		}
	}
}
```

Present the inspector and make a captured request:

```swift
import SwiftUI
import NetworkInspector

struct ContentView: View {
	@State private var isInspectorPresented = false

	var body: some View {
		VStack(spacing: 16) {
			Button("Open Inspector") {
				isInspectorPresented = true
			}

			Button("Send Test Request") {
				Task {
					let session = NetworkInspector.makeInstrumentedSession(configuration: .default)
					guard let url = URL(string: "https://httpbin.org/get") else { return }
					_ = try? await session.data(from: url)
				}
			}
		}
		.sheet(isPresented: $isInspectorPresented) {
			NetworkInspectorView()
		}
	}
}
```

## Quick Start: UIKit

Install at launch, then present the SwiftUI inspector in a hosting controller:

```swift
import UIKit
import NetworkInspector

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
	) -> Bool {
		_ = NetworkInspector.install()
		return true
	}
}
```

```swift
import UIKit
import SwiftUI
import NetworkInspector

final class ViewController: UIViewController {
	func showInspector() {
		let inspector = UIHostingController(rootView: NetworkInspectorView())
		present(inspector, animated: true)
	}
}
```

Use the instrumented session for requests that should appear in the inspector:

```swift
let session = NetworkInspector.makeInstrumentedSession(configuration: .default)
let url = URL(string: "https://httpbin.org/get")!
let (data, response) = try await session.data(from: url)
```

## Capturing URLSession Traffic

Create an instrumented session with the configuration you want. Ordinary `URLSession` instances are not automatically captured.

```swift
let session = NetworkInspector.makeInstrumentedSession(configuration: .default)
let url = URL(string: "https://httpbin.org/get")!
let request = URLRequest(url: url)

// Async/await with a URL
let (data, response) = try await session.data(from: url)

// Async/await with a URLRequest
let (requestData, requestResponse) = try await session.data(for: request)
```

## Manual Capture

Use manual capture for custom clients or flows that do not use the instrumented session. Manual entries go through the same redaction, truncation, and storage pipeline.

```swift
import NetworkInspector
import NetInspectorCore

let request = RequestLike(
	method: "POST",
	url: URL(string: "https://api.example.com/auth")!,
	headers: ["Content-Type": "application/json"],
	body: #"{"email":"ada@example.com","password":"secret"}"#.data(using: .utf8)
)

let response = ResponseLike(
	statusCode: 200,
	headers: ["Content-Type": "application/json"],
	body: #"{"ok":true}"#.data(using: .utf8)
)

NetworkInspector.log(request: request, response: response, source: .manual)
```

## Configuration

The default configuration enables capture in Debug builds and disables it in Release builds. Configuration types are in `NetInspectorCore`.

```swift
import NetInspectorCore
import NetworkInspector

var configuration = Configuration.default
configuration.maxEntries = 500
configuration.maxBodyBytes = 64 * 1024
configuration.captureBinaryBodies = false
configuration.includeTaskMetrics = true
configuration.redactHeaders = [
	"authorization", "cookie", "set-cookie", "x-api-key",
	"x-auth-token", "proxy-authorization"
]
configuration.redactBodyKeys = [
	.init(.exact("password")),
	.init(.exact("otp")),
	.init(.regex(".*token.*"))
]

NetworkInspector.updateConfiguration(configuration)
```

Pause capture temporarily, or disable it around sensitive asynchronous work:

```swift
NetworkInspector.pause()
// Perform work that should not be captured.
NetworkInspector.resume()

await NetworkInspector.withLoggingDisabled {
	// Sensitive asynchronous work.
}
```

`enable()` and `disable()` change the global capture setting after installation. Prefer the default Release behavior unless capture is intentionally needed for an internal build.

## Inspector and Export

Embed the inspector anywhere a SwiftUI view is appropriate:

```swift
NetworkInspectorView()
```

The inspector includes **Requests**, **Export**, and **Settings** tabs. To export entries from code:

```swift
let entries = await NetworkInspector.entries()
let jsonData = try NetworkInspector.exportJSON(entries: entries)

if let entry = entries.first {
	let curlCommand = NetworkInspector.exportCurl(entry: entry)
	print(curlCommand)
}
```

Exports use the sanitized entries held by the SDK. A truncated body remains marked as truncated; an export does not restore data that was omitted.

## Privacy and Safety

- Redaction is applied before captured entries are stored. It also applies to manual captures.
- Default protected headers, matched without regard to case: `Authorization`, `Cookie`, `Set-Cookie`, `X-API-Key`, `X-Auth-Token`, and `Proxy-Authorization`.
- Default protected JSON keys: `password`, `otp`, and keys matching the case-insensitive regular expression `.*token.*`.
- Body previews are limited to 64 KB by default. Likely binary bodies are omitted unless `captureBinaryBodies` is enabled.
- The SDK stores entries in memory; configure `maxEntries` to control the bound.
- Capture is disabled by default in Release builds, but can be explicitly enabled through configuration.
- NetworkInspector is a debugging tool, not a production analytics or monitoring service.

Review your app's privacy requirements before enabling capture or changing redaction rules. Redaction only protects the configured headers and JSON body keys; it is not a substitute for reviewing the data your app sends.

## Troubleshooting

### Requests do not appear

- Confirm the request uses a session created with `NetworkInspector.makeInstrumentedSession(configuration:)`. Existing sessions are not automatically instrumented.
- Confirm `NetworkInspector.install()` ran during app startup.
- Check the build configuration: capture is disabled by default in Release builds.
- Confirm capture has not been paused or disabled by configuration.
- For cleartext HTTP, check your app's App Transport Security settings. HTTPS is generally the simplest test setup.

### The export is empty

- Make at least one captured request and check that it appears in `await NetworkInspector.entries()`.
- cURL export accepts one entry at a time; JSON export accepts an array of entries.

### Headers or body fields are missing or say `REDACTED`

- This is expected for names matched by the configured redaction rules. Redaction happens before storage, so exports use the redacted values too.
- Check `maxBodyBytes` and the body's content type if the body preview is shortened or omitted.

### The inspector does not present

- In SwiftUI, present `NetworkInspectorView()` in a sheet or another view hierarchy.
- In UIKit, present a `UIHostingController` whose root view is `NetworkInspectorView()`.
- Confirm the app target imports `NetworkInspector` and runs on iOS 16 or later.

## Limitations

- URLSession capture requires the instrumented session created by this SDK.
- Upload/download capture is limited to the behavior supported by the current URLProtocol-based implementation.
- HAR export is not currently available.
- Integrations for third-party clients such as Alamofire, Moya, and Apollo are not included in the current release.

## API Overview

The app-facing facade is imported with `NetworkInspector`. `Configuration`, `RequestLike`, `ResponseLike`, and related core models are in `NetInspectorCore`.

- `install(configuration:)`, `updateConfiguration(_:)`, `isInstalled()`
- `enable()`, `disable()`, `pause()`, `resume()`, `withLoggingDisabled(_:)`
- `makeInstrumentedSession(configuration:)`
- `entries()`, `eventStream()`, `clear()`
- `exportJSON(entries:)`, `exportCurl(entry:)`
- `log(request:response:error:metrics:source:)` for manual capture

## Versioning

NetworkInspector follows Semantic Versioning. The current package version is `1.0.0`.

## License

MIT. See [LICENSE](LICENSE).
