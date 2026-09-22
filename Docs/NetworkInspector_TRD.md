Network Inspector for iOS
Technical Requirements Document
Product: Network Inspector
Platform: iOS
Language: Swift
Primary Distribution: Swift Package Manager
Additional Distribution: CocoaPods
Product Roadmap: V1.0 → V1.5 → V2.0 → V2.5 → V3.0 → V3.5 → V4.0
Document Type: Technical Requirements Document
Status: Working Specification

1. Document Purpose
This document defines the technical requirements for Network Inspector.
Network Inspector is an open-source network debugging and diagnostics SDK for iOS applications.
The SDK lets developers:
Capture network requests.
Inspect requests and responses.
Search network activity.
Filter network activity.
Identify failed requests.
View network timing.
Diagnose common network failures.
Reproduce requests.
Group requests into debug sessions.
Export network information.
Compare network activity.
Share safe diagnostic information.
This document defines:
Product architecture.
Module boundaries.
Public APIs.
Data models.
Capture architecture.
Processing architecture.
Privacy requirements.
Diagnostics architecture.
Actor boundaries.
Storage architecture.
Debug sessions.
Export architecture.
SwiftUI architecture.
Plugin architecture.
Distribution.
Testing.
Performance.
Build safety.
CI.
Version evolution from V1.0 to V4.0.

2. Product Definition
Network Inspector is a developer-focused debugging SDK.
It runs inside an iOS application.
It gives the developer a local interface for application network activity.
The SDK is intended primarily for:
Development builds.
QA builds.
Internal testing.
Debug builds.
Ad Hoc builds when enabled.
TestFlight builds when enabled.
Controlled diagnostic builds.
Network Inspector must be disabled in Release builds by default.
The SDK is not a production analytics platform.

3. Primary Product Goal
Network Inspector must help a developer:
Find, understand, reproduce, compare, and share a network problem without leaving the application.
Capture alone is not sufficient.
The SDK must make captured information easy to understand.

4. Core Technical Principles
4.1 Simple Integration
The normal setup must require minimal code.
Example:
NetworkInspector.install()

Advanced configuration must be optional.

4.2 One Source Tree
Swift Package Manager and CocoaPods must compile the same implementation source files.
Do not create duplicate implementations.
Do not use:
SPM/Core/Foo.swift
CocoaPods/Core/Foo.swift

Use:
Sources/NetworkInspectorCore/Foo.swift

Distribution-specific files can include:
Package.swift
NetworkInspector.podspec


4.3 Core Must Be Independent
NetworkInspectorCore must not depend on:
SwiftUI.
UIKit.
Alamofire.
Moya.
Apollo.
WebKit.
Core can depend on Foundation.

4.4 Capture Must Be Independent From UI
Capture code must not update UI state directly.
The capture pipeline must publish data through the Core event system.

4.5 Privacy Before Storage
Sensitive information must be removed before data enters:
Memory storage.
Disk storage.
Debug sessions.
UI models.
Exporters.
External sinks.
Raw captured data can exist only for the minimum time that processing requires.

4.6 Network Inspector Must Not Modify Application Traffic
Network Inspector can inspect application traffic.
It must not modify the request or response used by the application.
Body truncation must apply only to the inspector copy.

4.7 Bounded Resource Use
The SDK must use bounded:
Memory.
Disk space.
Request body capture.
Response body capture.
Event history.
The SDK must not allow uncontrolled storage growth.

4.8 Honest Capture Support
Network Inspector must not claim universal network capture.
Each capture mechanism must be documented as:
Fully supported.
Partially supported.
Manual instrumentation required.
Unsupported.

5. Platform Requirements
Initial requirements:
Minimum iOS: iOS 16
Swift: Swift 5.9+
Xcode: Xcode 15+

The public architecture must remain compatible with newer Swift versions.
The minimum deployment target can be reviewed before a major release.

6. High-Level Architecture
The complete processing flow is:
Network Source
      ↓
Capture Adapter
      ↓
Raw Capture Event
      ↓
Early Eligibility / Sampling
      ↓
Normalization
      ↓
Privacy / Redaction
      ↓
Body Truncation
      ↓
Diagnostics
      ↓
NetworkEntry
      ↓
Storage
      ↓
Event System
      ↓
┌────────────────┬────────────────┬────────────────┐
│ Inspector UI   │ Exporters      │ Plugins/Sinks  │
└────────────────┴────────────────┴────────────────┘


7. Supported Capture Sources
The complete product can support:
URLSession.
Async/await URLSession use.
Alamofire.
Moya.
Apollo GraphQL.
Upload tasks.
Download tasks.
Multipart requests.
Background URLSession where possible.
WKWebView where possible.
Manual logging.
Custom capture adapters.
URLSession is the primary V1.0 capture mechanism.

8. Module Architecture
The complete package can contain:
NetworkInspector

├── NetworkInspectorCore
├── NetworkInspectorURLSession
├── NetworkInspectorDiagnostics
├── NetworkInspectorUI
├── NetworkInspectorExporters
├── NetworkInspectorPersistence
│
├── NetworkInspectorAlamofire
├── NetworkInspectorMoya
├── NetworkInspectorApollo
├── NetworkInspectorWebKit
│
└── NetworkInspector
    └── Public Facade

Not all modules are required for V1.0.

9. Module Dependency Rules
The dependency direction must remain simple.
                    NetworkInspectorUI
                            │
                            ▼
                   NetworkInspectorCore
                            ▲
                            │
      ┌─────────────────────┼─────────────────────┐
      │                     │                     │
URLSession Capture     Diagnostics           Exporters
      │                     │                     │
      └─────────────────────┼─────────────────────┘
                            │
                            ▼
                    NetworkInspector
                     Public Facade

Optional integrations depend on Core.
Alamofire ─┐
Moya ──────┼──► NetworkInspectorCore
Apollo ────┤
WebKit ────┘

Core must not depend on optional integrations.

10. NetworkInspectorCore
Core owns the shared product model.
Recommended structure:
NetworkInspectorCore/

├── Configuration/
├── Models/
├── Capture/
├── Processing/
├── Privacy/
├── Storage/
├── Sessions/
├── Events/
├── Export/
├── Plugins/
└── Utilities/

Core responsibilities include:
Configuration.
Common data models.
Capture contracts.
Processing contracts.
Privacy rules.
Storage contracts.
Session contracts.
Event contracts.
Export contracts.
Plugin contracts.

11. NetworkInspectorURLSession
This module owns URLSession instrumentation.
Recommended structure:
NetworkInspectorURLSession/

├── URLProtocol/
├── Session/
├── Tracking/
├── Delegates/
├── Metrics/
├── Uploads/
└── Downloads/

Responsibilities include:
URLProtocol interception.
Instrumented URLSession creation.
Request tracking.
Response tracking.
Recursive capture prevention.
URLSession task metrics.
Upload metadata.
Download metadata.
Dependencies:
Foundation.
NetworkInspectorCore.

12. NetworkInspectorDiagnostics
This module owns diagnostic analysis.
Recommended structure:
NetworkInspectorDiagnostics/

├── Classification/
├── Rules/
├── Timing/
├── Comparison/
├── Grouping/
└── Diff/

V1.0 includes basic classification.
Later versions add comparison and analysis.

13. NetworkInspectorUI
This module owns the user interface.
Recommended structure:
NetworkInspectorUI/

├── ViewModels/
├── Views/
├── Components/
├── RequestList/
├── RequestDetails/
├── Search/
├── Filters/
├── Sessions/
├── Comparison/
├── Presentation/
├── Theme/
└── Resources/

Dependencies:
Foundation.
SwiftUI.
NetworkInspectorCore.
NetworkInspectorDiagnostics where required.
UIKit can be imported only when needed for:
Clipboard access.
UIViewController presentation.
UIKit presentation helpers.

14. NetworkInspectorExporters
This module owns exporter implementations.
Recommended structure:
NetworkInspectorExporters/

├── Curl/
├── JSON/
└── HAR/

Core owns only the exporter contracts.

15. Framework Integration Modules
Framework integrations must remain separate.
Examples:
NetworkInspectorAlamofire
NetworkInspectorMoya
NetworkInspectorApollo
NetworkInspectorWebKit

This prevents an application from installing dependencies that it does not use.

16. Public Facade
The main application-facing module is:
import NetworkInspector

The facade must contain minimal implementation logic.
Example public API:
public enum NetworkInspector {

    public static func install(
        configuration: Configuration = .default
    )

    public static func updateConfiguration(
        _ configuration: Configuration
    )

    public static func isInstalled() -> Bool

    public static func enable()

    public static func disable()

    public static func clear() async

    public static func entries() async -> [NetworkEntry]

    public static func eventStream()
        -> AsyncStream<NetworkEvent>

    public static func makeInstrumentedSession(
        configuration: URLSessionConfiguration
    ) -> URLSession
}

Session and export APIs are defined later in this document.

17. Runtime Architecture
Network Inspector must use one internal runtime.
Conceptually:
final class NetworkInspectorRuntime {

    let configurationStore: ConfigurationStore
    let networkStore: NetworkStore
    let sessionStore: SessionStore
    let captureCoordinator: CaptureCoordinator
    let diagnosticsEngine: DiagnosticsEngine
}

Optional registries can include:
ExporterRegistry
PluginRegistry
SinkRegistry

Do not create an actor only because a type is a registry.
Use actor isolation only when the type owns mutable shared state.

18. Actor Architecture
Recommended actor-isolated state:
ConfigurationStore
NetworkStore
SessionStore
CaptureCoordinator
RuntimeRegistry

An immutable registry does not require actor isolation.
The architecture should minimize unnecessary await boundaries.

19. Configuration Store
Example:
public actor ConfigurationStore {

    private var configuration: Configuration

    public func current() -> Configuration

    public func update(
        _ configuration: Configuration
    )
}

Configuration updates must be safe during concurrent network activity.

20. Primary Data Model
The primary public network model is NetworkEntry.
public struct NetworkEntry:
    Identifiable,
    Codable,
    Sendable,
    Hashable {

    public let id: UUID
    public let createdAt: Date

    public let source: NetworkSource

    public let request: NetworkRequest
    public let response: NetworkResponse?

    public let metrics: NetworkMetrics?
    public let diagnostics: NetworkDiagnostics?

    public let flags: NetworkFlags
}

Use immutable values where practical.

21. NetworkSource
Example:
public enum NetworkSource:
    String,
    Codable,
    Sendable {

    case urlSession
    case alamofire
    case moya
    case apollo
    case web
    case manual
    case custom
}


22. NetworkRequest
public struct NetworkRequest:
    Codable,
    Sendable,
    Hashable {

    public let method: String
    public let url: NetworkURL

    public let headers: [NetworkHeader]

    public let body: BodySample?

    public let actualBodySize: Int64?
    public let capturedBodySize: Int64?

    public let contentType: String?
}


23. NetworkURL
The URL model should expose safe structured values.
Example:
public struct NetworkURL:
    Codable,
    Sendable,
    Hashable {

    public let absoluteString: String

    public let scheme: String?
    public let host: String?
    public let path: String

    public let queryItems: [NetworkQueryItem]
}

The SDK must support query-value redaction where required.

24. NetworkResponse
public struct NetworkResponse:
    Codable,
    Sendable,
    Hashable {

    public let statusCode: Int?

    public let headers: [NetworkHeader]

    public let body: BodySample?

    public let actualBodySize: Int64?
    public let capturedBodySize: Int64?

    public let contentType: String?

    public let error: NetworkError?
}


25. NetworkError
Use a structured error model when possible.
public struct NetworkError:
    Codable,
    Sendable,
    Hashable {

    public let domain: String?
    public let code: Int?
    public let description: String
}

The model must not depend on the original Error instance after storage.

26. BodySample
A body sample represents the inspector copy of a body.
public struct BodySample:
    Codable,
    Sendable,
    Hashable {

    public let data: Data
    public let contentType: String?

    public let isTruncated: Bool
    public let isBinary: Bool
}

The exact public form can change if a more memory-efficient representation is required.

27. NetworkMetrics
public struct NetworkMetrics:
    Codable,
    Sendable,
    Hashable {

    public let startedAt: Date?
    public let endedAt: Date?

    public let totalDuration: TimeInterval?

    public let dnsDuration: TimeInterval?
    public let connectionDuration: TimeInterval?
    public let tlsDuration: TimeInterval?

    public let requestDuration: TimeInterval?
    public let serverWaitDuration: TimeInterval?
    public let responseDuration: TimeInterval?

    public let redirectCount: Int?
}

Metrics can be unavailable.
The UI must handle missing metrics.

28. Metric Accuracy
Where a value can be estimated, the SDK must identify its accuracy.
public enum MetricAccuracy:
    String,
    Codable,
    Sendable {

    case exact
    case estimated
    case unknown
}

The UI must not show estimated values as exact values.

29. Network Flags
Possible flags include:
isRedacted
isTruncated
isUpload
isDownload
hasError
containsBinaryContent
containsEstimatedValues

Later versions can add:
isPinned
isImported


30. Capture Adapter Protocol
All capture mechanisms should use one common abstraction where practical.
public protocol NetworkCaptureAdapter:
    Sendable {

    var source: NetworkSource { get }

    func start() async

    func stop() async
}

Examples:
URLSessionCaptureAdapter
AlamofireCaptureAdapter
MoyaCaptureAdapter
ApolloCaptureAdapter
WebCaptureAdapter

Not all adapters must run at the same time.

31. Raw Capture Event
Adapters produce internal raw events.
struct CaptureEvent: Sendable {

    let id: UUID
    let timestamp: Date

    let source: NetworkSource

    let request: RawRequestCapture
    let response: RawResponseCapture?

    let error: CapturedError?
    let metrics: NetworkMetrics?
}

Raw capture events must not enter persistent storage.

32. Processing Pipeline
The processing pipeline is:
CaptureEvent
    ↓
Early Eligibility / Sampling
    ↓
Normalization
    ↓
Privacy / Redaction
    ↓
Body Truncation
    ↓
Diagnostics
    ↓
NetworkEntryFactory
    ↓
NetworkStore

Each stage must have a clear responsibility.
Processing components should remain stateless where practical.

33. Sampling
Sampling must happen early.
Possible policies include:
.all
.errorsOnly
.percentage(Double)
.custom(...)

A request that is rejected by an early policy should not go through expensive body processing.

34. Normalization
Normalization converts framework-specific information into the shared model.
Normalization must handle:
URL.
Method.
Headers.
Query values.
Request body.
Response status.
Response headers.
Response body.
Errors.
Size metadata.
Timing metadata.

35. Privacy and Redaction
Privacy processing must occur before storage.
Default protected headers:
Authorization
Cookie
Set-Cookie
X-API-Key
X-Auth-Token
Proxy-Authorization

Header comparison must not depend on letter case.
Default protected JSON fields:
password
token
secret
otp
pin
access_token
refresh_token


36. JSON Redaction Rules
Example:
public enum JSONRedactionRule:
    Sendable,
    Hashable {

    case exact(String)
    case regex(String)
}

Redaction must process:
Top-level objects.
Nested objects.
Arrays.
Objects inside arrays.
Example:
{
  "user": {
    "password": "secret"
  }
}

must become:
{
  "user": {
    "password": "REDACTED"
  }
}

before storage.

37. Query Redaction
The privacy system should also support URL query values.
Example sensitive keys can include:
token
api_key
access_token
secret

Applications must be able to configure these rules.

38. Capture Suppression
Applications must be able to disable capture temporarily.
Example:
NetworkInspector.pause()

NetworkInspector.resume()

A scoped API should also exist:
NetworkInspector.withLoggingDisabled {
    // Sensitive operation
}

The exact concurrency form can be adapted for async operations.

39. Body Capture Policy
Recommended V1.0 default:
Maximum captured body: 64 KB

The SDK must distinguish:
Actual Body Size
Captured Body Size

Example:
Actual:   4.2 MB
Captured: 64 KB

The application payload must not be truncated.
Only the inspector copy can be truncated.

40. Binary Data Policy
Default V1.0 behavior:
Text        Capture
JSON        Capture and redact
Binary      Do not capture body
Multipart   Metadata only
Upload      Metadata and size
Download    Metadata and size

Possible policies:
.captureNone
.captureMetadataOnly
.captureText
.captureSample(maxBytes:)


41. URLSession Capture
V1.0 uses URLSession as the primary networking system.
A custom URLProtocol can provide interception where supported.
The implementation must:
Receive an eligible request.
Assign a capture ID.
Mark the request as handled.
Forward the original request.
Capture response metadata.
Capture only the allowed body sample.
Forward application data unchanged.
Capture completion.
Send the event to the processing pipeline.

42. Recursive Capture Prevention
Use a URLProtocol property marker.
Example:
static let handledKey =
    "com.networkinspector.urlprotocol.handled"

Before forwarding:
URLProtocol.setProperty(
    true,
    forKey: handledKey,
    in: mutableRequest
)

A marked request must not be intercepted again.

43. Request Tracking
Each request must have an internal capture ID.
Example:
let captureID = UUID()

The capture ID connects:
Request
Response
Metrics
Completion

It does not need to be part of the public API.

44. Instrumented URLSession
The SDK must provide an explicit session API.
let session =
    NetworkInspector.makeInstrumentedSession(
        configuration: .default
    )

The implementation can insert the Network Inspector protocol class into a compatible URLSession configuration.
Documentation must state the limitations of URLProtocol interception.

45. Data Tasks
Capture:
HTTP method.
URL.
Query parameters.
Headers.
Request body sample.
Request body size.
Response status.
Response headers.
Response body sample.
Response body size.
Error.
Timing where available.

46. Upload Tasks
V1.0 requires basic upload information.
Capture:
URL.
Method.
Headers.
Content type.
Upload size.
Response information.
Error.
Do not capture binary upload data by default.
Later versions can add:
Progress.
Multipart details.
Part metadata.

47. Download Tasks
V1.0 requires basic download information.
Capture:
Request metadata.
Response status.
Response headers.
Expected size.
Downloaded size where known.
Duration.
Error.
Do not store downloaded file contents by default.

48. Manual Capture
Applications must be able to submit network activity manually.
This supports:
Custom HTTP clients.
Third-party SDKs.
Non-standard networking systems.
Unsupported capture implementations.
Example concept:
NetworkInspector.log(
    request: request,
    response: response,
    error: error,
    metrics: metrics
)

Manual capture must use the same pipeline as automatic capture.
Do not create a separate storage path.

49. Diagnostics Architecture
Diagnostics are a first-class product feature.
Diagnostics must help the developer understand a request.
The diagnostic engine must not guess.
It must use available request, response, error, and timing information.

50. NetworkDiagnostics
Example:
public struct NetworkDiagnostics:
    Codable,
    Sendable,
    Hashable {

    public let classification: NetworkClassification
    public let issues: [DiagnosticIssue]
}


51. Network Classification
Initial values:
public enum NetworkClassification:
    String,
    Codable,
    Sendable {

    case success
    case redirect
    case clientError
    case serverError
    case networkFailure
    case timeout
    case cancelled
    case slow
    case noResponse
    case unknown
}


52. Diagnostic Rules
V1.0 rules can use clear facts.
Examples:
2xx → Success
3xx → Redirect
4xx → Client Error
5xx → Server Error
Timeout error → Timeout
Cancellation error → Cancelled
No HTTP response + network error → Network Failure

Do not infer application-specific causes unless the captured response supports them.

53. Slow Request Detection
V1.5 adds slow-request detection.
The threshold must be configurable.
Example:
slowRequestThreshold: 2.0

A slow request must be identified as a performance condition.
It must not automatically be identified as a network failure.

54. Network Store
V1.0 uses bounded in-memory storage.
Example:
public actor NetworkStore {

    public func insert(
        _ entry: NetworkEntry
    )

    public func entries()
        -> [NetworkEntry]

    public func entry(
        id: UUID
    ) -> NetworkEntry?

    public func clear()

    public func stream()
        -> AsyncStream<NetworkEvent>
}


55. Memory Limits
Recommended defaults:
Maximum entries: 500
Maximum captured body: 64 KB

When the entry limit is reached:
Insert newest
     ↓
Check capacity
     ↓
Remove oldest

A ring buffer is preferred where practical.

56. Network Event Model
public enum NetworkEvent:
    Sendable {

    case inserted(NetworkEntry)
    case updated(NetworkEntry)
    case removed(UUID)
    case cleared
}

updated is required because metrics or other late information can arrive after an initial event.

57. Debug Sessions
Debug sessions are part of V1.0.
A session groups network activity for one debugging task.
Example:
Checkout Failure

Started: 14:32
Duration: 2m 14s

Requests: 27
Failures: 3


58. DebugSession Model
public struct DebugSession:
    Identifiable,
    Codable,
    Sendable,
    Hashable {

    public let id: UUID
    public let name: String?

    public let startedAt: Date
    public let endedAt: Date?

    public let entryIDs: [UUID]

    public let metadata: SessionMetadata
}

A session should reference entries.
Do not duplicate body data inside the session object.

59. Session Metadata
Possible safe metadata:
public struct SessionMetadata:
    Codable,
    Sendable,
    Hashable {

    public let applicationVersion: String?
    public let buildNumber: String?
    public let operatingSystemVersion: String?
    public let deviceModel: String?
    public let environment: String?
}

Do not capture sensitive device identifiers by default.

60. Session Store
Example:
public actor SessionStore {

    public func start(
        name: String?
    ) -> DebugSession

    public func stopCurrent()
        -> DebugSession?

    public func current()
        -> DebugSession?

    public func sessions()
        -> [DebugSession]
}

The exact public API can remain behind the facade.

61. Public Session API
Conceptual API:
let session =
    await NetworkInspector.startSession(
        name: "Checkout Failure"
    )

Stop:
let session =
    await NetworkInspector.stopSession()

Inspect:
let session =
    await NetworkInspector.currentSession()

Exact naming can change before API stabilization.

62. Export Architecture
Core defines exporter contracts.
Exporter implementations live in NetworkInspectorExporters.
Example generic contract:
public protocol NetworkExporter:
    Sendable {

    associatedtype Output

    var identifier: String { get }

    func export(
        entries: [NetworkEntry]
    ) throws -> Output
}

A type-erased form can be used by the public registry.

63. V1.0 Export Formats
V1.0 must support:
cURL.
JSON.
HAR is added later.

64. cURL Export
The cURL exporter must use sanitized data only.
Removed secrets must remain removed.
If body data is truncated, the exporter must not create a request that appears complete.
Possible behavior:
Omit the incomplete body.
Clearly mark the export as incomplete.

65. JSON Export
JSON export must support:
One entry.
Multiple entries.
One debug session.
The JSON format should include:
Request information.
Response information.
Metrics.
Diagnostics.
Redaction flags.
Truncation flags.
Session information where applicable.

66. HAR Export
V1.5 adds HAR 1.2 support where captured information is sufficient.
HAR export must obey:
Redaction.
Truncation.
Binary capture rules.
The exporter must not invent unavailable timing data.

67. SwiftUI Inspector
Public entry point:
public struct NetworkInspectorView: View

V1.0 hierarchy:
NetworkInspectorView

├── RequestList
│   ├── Search
│   ├── QuickFilters
│   └── NetworkEntryRow
│
├── NetworkEntryDetail
│   ├── Summary
│   ├── Request
│   ├── Response
│   ├── Headers
│   ├── Body
│   ├── Timing
│   ├── Diagnostics
│   └── Export
│
└── DebugSessions
    ├── SessionList
    └── SessionDetail


68. Request List
Each row should provide fast information.
Recommended content:
POST /v1/checkout

422 • 842 ms • 486 B
api.example.com

The row can show:
Method.
Relative path.
Host.
Status.
Duration.
Response size.
Error indicator.

69. Status Presentation
Status groups:
2xx  Success
3xx  Redirect
4xx  Client Error
5xx  Server Error
Network Error

The UI should also clearly show:
Timeout
Cancelled
No Response


70. Search
V1.0 search should support:
Full URL.
Host.
Path.
HTTP method.
Later versions can add:
GraphQL operation.
Tags.
Notes.
Body search where allowed.
Sensitive body search must not be enabled by default.

71. V1.0 Filters
Support:
HTTP method.
Status.
Status range.
Host.
Error state.
Quick filters:
All
Failed
4xx
5xx


72. V1.5 Filters
Add:
Slow
Uploads
Downloads
Has Request Body
Has Response Body

Later versions can add framework-specific filters.

73. Request Detail Screen
Recommended sections:
Summary
Request
Response
Query Parameters
Request Headers
Request Body
Response Headers
Response Body
Sizes
Timing
Diagnostics
Export

Each useful value should support copy actions.

74. Diagnostics UI
A failed request can show:
POST /checkout

Status
422 Client Error

Duration
842 ms

Diagnosis
Server rejected the request.

Response
delivery_address is required

Do not show a specific cause unless the data supports that cause.

75. UI Feedback
Use simple feedback for actions.
Examples:
Copied
Export Created
Session Started
Session Stopped
Logs Cleared

Avoid unnecessary animation.

76. Theme Requirements
V1.0 must support:
Light appearance.
Dark appearance.
System text sizing where practical.
Advanced theme customization is not a V1.0 priority.
The architecture can still use a central theme model.
Do not hard-code style values throughout the view hierarchy.

77. Presentation
V1.0 supports:
NetworkInspectorView()

for embedding.
It also supports:
NetworkInspector.present(
    from: viewController
)

Later versions can add:
Shake gesture.
Triple tap.
Deep link.
Floating button.
Custom presentation triggers.
These features do not define a major product version.

78. Resource Resolution
SPM and CocoaPods handle resources differently.
All UI resources must use one resolver.
Example:
enum NetworkInspectorResourceBundle {

    static var bundle: Bundle {

        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return cocoaPodsBundle
        #endif
    }
}

Do not use Bundle.main for SDK resources.
Do not use Bundle.module directly outside the resolver.

79. Swift Package Manager Distribution
SPM is the primary distribution mechanism.
Recommended primary product:
.library(
    name: "NetworkInspector",
    targets: [
        "NetworkInspector"
    ]
)

Internal targets provide clean boundaries.
V1.0 targets can include:
NetworkInspectorCore
NetworkInspectorURLSession
NetworkInspectorDiagnostics
NetworkInspectorExporters
NetworkInspectorUI
NetworkInspector


80. CocoaPods Distribution
CocoaPods should expose:
NetworkInspector

Optional integrations should use subspecs.
Possible structure:
NetworkInspector/Core
NetworkInspector/URLSession
NetworkInspector/Diagnostics
NetworkInspector/UI
NetworkInspector/Export
NetworkInspector/Alamofire
NetworkInspector/Moya
NetworkInspector/Apollo
NetworkInspector/WebKit

Optional framework integrations must not install automatically.

81. Distribution API Consistency
A developer using SPM:
import NetworkInspector

and a developer using CocoaPods:
import NetworkInspector

must use the same main public API.
Distribution must not change normal application code.

82. Alamofire Integration
V2.0 adds first-class Alamofire support.
Possible integration methods:
Instrumented session configuration.
Alamofire EventMonitor.
Capture:
Request.
Response.
Error.
Timing.
Framework-specific metadata where useful.
All captured data must enter the normal processing pipeline.

83. Moya Integration
V2.0 adds Moya support.
Possible API:
NetworkInspector.makeMoyaPlugin()

Capture:
Target metadata.
Generated URLRequest.
HTTP method.
Headers.
Body metadata.
Response.
Error.
All data must normalize into NetworkEntry.

84. Apollo GraphQL Integration
V2.0 adds Apollo GraphQL support.
Capture where practical:
Operation name.
Operation type.
Variables.
HTTP request.
HTTP response.
GraphQL errors.
Network errors.
GraphQL variables must use the standard privacy pipeline.

85. GraphQL Model
GraphQL metadata should remain structured.
Example:
Operation Name
CreateOrder

Operation Type
Mutation

HTTP Status
200

GraphQL Errors
1

Do not depend only on raw JSON body inspection.

86. Multipart Support
V1.0 captures metadata only.
Later versions can capture:
Boundary metadata.
Total size.
Part names.
MIME types.
Part sizes.
Text parts where allowed.
Binary part bodies remain disabled by default.

87. Background URLSession
Background sessions have different platform behavior.
Network Inspector must not promise complete interception.
V3.5 can provide:
Compatible configuration helpers.
Delegate instrumentation.
Manual completion logging.
Clear support status.

88. WKWebView Support
WKWebView support is an optional V3.5 feature.
The plugin can observe:
fetch.
XMLHttpRequest.
Captured information can pass to native code through WKScriptMessageHandler.
This feature must be:
Optional.
Disabled by default.
Isolated from Core.
Clearly documented.

89. Request Comparison
V2.5 adds request comparison.
Compare:
URL.
Query parameters.
Headers.
Request body.
Response body.
Status.
Timing.
Environment.
Example:
                Request A     Request B

Status           200           422
Duration         410 ms        690 ms
Environment      Staging       Production

addressId        "123"         Missing

Sensitive information must remain redacted.

90. Structured Diff
V2.5 can provide:
JSON diff.
Header diff.
Query diff.
Response diff.
Comparison must operate on sanitized data.

91. Request Grouping
V2.5 can group network activity by:
Host.
Endpoint.
Status.
Failure type.
Network source.
Session.
Grouping must help diagnosis.
Do not add grouping only for visual complexity.

92. Session Comparison
V2.5 can compare two debug sessions.
Useful comparisons include:
Request count.
Failure count.
Endpoint differences.
Timing changes.
Status differences.

93. Team Diagnostic Packages
V3.0 adds shareable diagnostic packages.
A package can contain:
Debug session.
Sanitized network entries.
Application version.
Build version.
OS version.
Safe device information.
Environment.
Diagnostics.
The package must not include raw secrets.

94. Session Import
V3.0 must support importing a supported diagnostic package.
Imported sessions must be marked as imported.
The inspector must allow offline inspection.
Imported data must not be treated as live network traffic.

95. Persistence
V1.5 adds optional disk persistence.
Possible implementation:
SQLite.
File-backed records.
The selected implementation must prioritize:
Predictable behavior.
Bounded storage.
Crash-safe writes.
Simple migration.

96. Persistence Policy
Configuration should include:
enabled
maxDiskMB
retentionDays

The store must support:
Maximum disk size.
Retention period.
Background writes.
Batched writes.
Automatic eviction.
Clear on demand.
Persistence remains optional.

97. Encryption at Rest
Encrypted storage can be considered for later versions.
If implemented:
Encryption must be optional or clearly documented.
Keys must not be stored with encrypted payloads in an unsafe way.
Redaction must still occur before persistence.
Encryption does not replace redaction.

98. Plugin Architecture
V4.0 provides stable extension contracts.
Examples:
NetworkCaptureAdapter
NetworkStore
NetworkExporter
NetworkSink
NetworkDiagnosticRule
NetworkRedactionRule
NetworkInspectorPlugin

Core must not depend on plugin implementations.

99. Custom Diagnostic Rules
V4.0 can allow applications to provide rules.
Example concept:
public protocol NetworkDiagnosticRule:
    Sendable {

    func evaluate(
        entry: NetworkEntry
    ) -> DiagnosticIssue?
}

Rules must operate on sanitized data.

100. External Sinks
External sinks are opt-in.
Possible sinks include:
OSLog.
Internal diagnostic systems.
Error reporting tools.
No external sink is enabled by default.
A sink must receive sanitized data only.

101. Concurrency Model
Recommended flow:
Capture Callback
      ↓
Background Processing
      ↓
CaptureCoordinator
      ↓
NetworkStore Actor
      ↓
AsyncStream
      ↓
MainActor UI

Only UI state should require MainActor.
Core processing must not require the main thread.

102. Performance Requirements
The SDK must:
Avoid blocking the main thread.
Keep memory bounded.
Keep disk use bounded.
Avoid unnecessary Data copies.
Parse large bodies lazily where possible.
Apply sampling early.
Apply privacy rules before storage.
Batch disk operations.
Avoid expensive work while disabled.

103. Performance Measurements
Tests should measure:
Requests per second.
CPU overhead.
Memory growth.
Storage growth.
Large response behavior.
Large request behavior.
Concurrent request behavior.
Rapid UI updates.
Session growth.
Disk limit enforcement.

104. Unit Testing
Unit tests must cover:
Normalization.
Redaction.
Nested JSON redaction.
Regex redaction.
Query redaction.
Truncation.
Sampling.
Size accounting.
Diagnostics.
Storage.
Sessions.
Exporters.
Comparison logic when added.

105. URLSession Integration Testing
Test:
GET.
POST.
Async/await.
Redirects.
Failures.
Timeouts.
Cancellation.
Upload metadata.
Download metadata.
Recursive capture prevention.
Body truncation.
Metrics where available.

106. Framework Integration Testing
As integrations are added, test:
Alamofire.
Moya.
Apollo.
Multipart.
WebKit.
Framework test targets should remain isolated.

107. UI Testing
Test:
Empty state.
Request list.
Request detail.
Search.
Filters.
Error requests.
Redacted content.
Truncated content.
Dark appearance.
Light appearance.
Debug session list.
Debug session detail.
Later tests add:
Comparison.
Imported sessions.
Grouping.

108. Build Safety
Recommended default:
DEBUG
Can be enabled.

Release
Disabled by default.

Explicit configuration is required for:
Ad Hoc builds.
TestFlight.
Internal diagnostic builds.
Network Inspector must not silently enable itself in production.

109. Compile-Time Exclusion
The project should support a simple method for applications that want to exclude or disable the SDK from production code.
The exact strategy can be documented during implementation.
Runtime disabling alone must not be presented as compile-time exclusion.

110. CI Requirements
Every pull request must verify the supported distribution paths.
SPM:
Resolve package
Build package
Run tests
Build example application

CocoaPods:
pod lib lint
Install example pods
Build example application
Run integration tests

A distribution feature is not complete until both supported installation methods work.

111. Example Applications
The repository should include:
Examples/

├── SPMExample/
├── CocoaPodsExample/
└── DemoApp/

The Demo App should show:
Successful requests.
Failed requests.
Slow requests.
JSON bodies.
Redacted fields.
Large responses.
Upload metadata.
Download metadata.
Debug sessions.

112. Repository Structure
Recommended mature structure:
NetworkInspector/

├── Package.swift
├── NetworkInspector.podspec
├── README.md
├── CHANGELOG.md
├── LICENSE
│
├── Sources/
│
│   ├── NetworkInspector/
│   │   ├── NetworkInspector.swift
│   │   ├── NetworkInspectorRuntime.swift
│   │   ├── NetworkInspectorInstaller.swift
│   │   └── Exports.swift
│   │
│   ├── NetworkInspectorCore/
│   │   ├── Configuration/
│   │   ├── Models/
│   │   ├── Capture/
│   │   ├── Processing/
│   │   ├── Privacy/
│   │   ├── Storage/
│   │   ├── Sessions/
│   │   ├── Events/
│   │   ├── Export/
│   │   ├── Plugins/
│   │   └── Utilities/
│   │
│   ├── NetworkInspectorDiagnostics/
│   │   ├── Classification/
│   │   ├── Rules/
│   │   ├── Timing/
│   │   ├── Comparison/
│   │   ├── Grouping/
│   │   └── Diff/
│   │
│   ├── NetworkInspectorURLSession/
│   │   ├── URLProtocol/
│   │   ├── Session/
│   │   ├── Tracking/
│   │   ├── Delegates/
│   │   ├── Metrics/
│   │   ├── Uploads/
│   │   └── Downloads/
│   │
│   ├── NetworkInspectorUI/
│   │   ├── ViewModels/
│   │   ├── Views/
│   │   ├── RequestList/
│   │   ├── RequestDetails/
│   │   ├── Sessions/
│   │   ├── Search/
│   │   ├── Filters/
│   │   ├── Comparison/
│   │   ├── Components/
│   │   ├── Presentation/
│   │   ├── Theme/
│   │   └── Resources/
│   │
│   ├── NetworkInspectorExporters/
│   │   ├── Curl/
│   │   ├── JSON/
│   │   └── HAR/
│   │
│   ├── NetworkInspectorPersistence/
│   ├── NetworkInspectorAlamofire/
│   ├── NetworkInspectorMoya/
│   ├── NetworkInspectorApollo/
│   └── NetworkInspectorWebKit/
│
├── Tests/
│
│   ├── NetworkInspectorCoreTests/
│   ├── NetworkInspectorDiagnosticsTests/
│   ├── NetworkInspectorURLSessionTests/
│   ├── NetworkInspectorUITests/
│   ├── NetworkInspectorExporterTests/
│   └── NetworkInspectorIntegrationTests/
│
├── Examples/
│   ├── SPMExample/
│   ├── CocoaPodsExample/
│   └── DemoApp/
│
├── Docs/
├── Scripts/
│
└── .github/
    └── workflows/
        ├── spm.yml
        ├── cocoapods.yml
        ├── tests.yml
        └── release.yml


113. V1.0 — Core Network Inspector
Goal
V1.0 must provide a complete basic network debugging workflow.
It must not be only an architectural foundation.
The workflow is:
Capture
   ↓
Find
   ↓
Inspect
   ↓
Understand
   ↓
Reproduce
   ↓
Export


114. V1.0 Capture Requirements
V1.0 includes:
URLSession capture.
Async/await support.
Data tasks.
Manual capture.
Basic upload metadata.
Basic download metadata.
Request headers.
Response headers.
Text body capture.
JSON body capture.
Network errors.
Basic redirect information.

115. V1.0 Privacy Requirements
V1.0 includes:
Header redaction.
JSON field redaction.
Nested JSON redaction.
Query redaction support.
Body truncation.
Binary body capture disabled by default.
Release build disabled by default.
Capture suppression.

116. V1.0 Inspection Requirements
V1.0 includes:
Request list.
Request detail.
Response detail.
Headers.
Query parameters.
Text body viewer.
JSON body viewer.
Error display.
Basic timing.
Request sizes.
Response sizes.

117. V1.0 Discovery Requirements
V1.0 includes:
Search.
HTTP method filter.
Status filter.
Host filter.
Error filter.
Quick filters:
All
Failed
4xx
5xx


118. V1.0 Diagnostics Requirements
Classify:
Success.
Redirect.
Client error.
Server error.
Network failure.
Timeout.
Cancelled.
No response.
Unknown.

119. V1.0 Session Requirements
V1.0 includes:
Start session.
Stop session.
Current session.
Session request count.
Session failure count.
Session list.
Session detail.
Session JSON export.

120. V1.0 Export Requirements
V1.0 includes:
cURL export.
JSON export.
Session JSON export.
All export must use sanitized information.

121. V1.0 Storage Requirements
V1.0 uses:
Bounded memory storage.
Maximum entry count.
Maximum body capture.
No disk persistence is required for V1.0.

122. V1.0 Definition of Done
V1.0 is complete when all requirements below work.
Distribution
Install through Swift Package Manager.
Install through CocoaPods.
Build successfully.
Use the same public facade.
Capture
Capture GET.
Capture POST.
Capture headers.
Capture query parameters.
Capture response metadata.
Capture bounded text bodies.
Capture bounded JSON bodies.
Capture failures.
Capture basic upload metadata.
Capture basic download metadata.
Prevent recursive URLProtocol capture.
Support manual capture.
Privacy
Redact default sensitive headers.
Redact configured JSON fields.
Redact nested JSON.
Truncate large bodies.
Do not capture binary bodies by default.
Do not store raw sensitive information.
Diagnostics
Classify HTTP success.
Classify redirects.
Classify 4xx responses.
Classify 5xx responses.
Classify network failures.
Classify timeout.
Classify cancellation.
UI
Display request list.
Display request detail.
Display response detail.
Search.
Filter.
Clear.
Copy useful values.
Show redaction state.
Show truncation state.
Show diagnostics.
Sessions
Start session.
Stop session.
Show session.
Show request count.
Show failure count.
Export session.
Export
Generate cURL.
Generate JSON.
Use sanitized data only.
Identify incomplete body data.
Performance
Keep memory bounded.
Keep body capture bounded.
Do not perform UI work on networking threads.
Do not mutate UI directly from capture code.
Do not modify application traffic.

123. V1.0 Recommended Implementation Order
Milestone 1 — Core Models
Build:
Configuration.
NetworkEntry.
NetworkRequest.
NetworkResponse.
NetworkURL.
NetworkMetrics.
NetworkError.
NetworkFlags.

Milestone 2 — Processing
Build:
Capture contracts.
Manual capture.
Sampling.
Normalization.
Redaction.
Query redaction.
Body truncation.

Milestone 3 — Storage and Events
Build:
NetworkStore.
Bounded memory behavior.
AsyncStream events.
Clear behavior.

Milestone 4 — URLSession Capture
Build:
URLProtocol.
Recursive capture prevention.
Capture ID.
Instrumented URLSession.
Request capture.
Response capture.
Error capture.
Basic metrics.

Milestone 5 — Diagnostics
Build:
Status classification.
Error classification.
Timeout classification.
Cancellation classification.

Milestone 6 — Inspector UI
Build:
Request list.
Request row.
Request detail.
Response detail.
Search.
Basic filters.
Diagnostics section.
Copy actions.

Milestone 7 — Debug Sessions
Build:
DebugSession.
SessionMetadata.
SessionStore.
Start session.
Stop session.
Session list.
Session detail.

Milestone 8 — Export
Build:
cURL exporter.
JSON exporter.
Session JSON exporter.

Milestone 9 — Distribution
Verify:
Package.swift.
Podspec.
Resource resolver.
SPM example.
CocoaPods example.
CI.
Release build safety.

124. V1.5 — Professional Inspection
Goal
Improve daily debugging speed and request analysis.
Add:
URLSessionTaskMetrics.
Detailed timing.
Slow-request detection.
Advanced search.
Advanced filters.
Persistent storage.
Retention policies.
HAR export.
Improved body viewer.
Improved JSON viewer.
Request pinning.
Better multipart metadata.

125. V1.5 Metrics
Add detailed timing where the platform provides it.
Possible information:
DNS.
Connection.
TLS.
Request.
Server wait.
Response.
Total time.
Redirect count.
Missing values must remain missing.
Do not estimate when the SDK cannot make a reliable estimate.

126. V1.5 Persistence
Add:
NetworkInspectorPersistence

Requirements:
Optional.
Bounded.
Retention policy.
Disk limit.
Background writes.
Batched writes.
Automatic cleanup.

127. V2.0 — iOS Networking Ecosystem
Goal
Provide one inspector for the main iOS networking approaches.
Add:
Alamofire.
Moya.
Apollo GraphQL.
GraphQL metadata.
Better uploads.
Better downloads.
Capture source indicators.
Duplicate capture detection.
Stable capture adapter contracts.

128. Duplicate Capture Detection
Multiple adapters can observe the same request.
The SDK must avoid showing duplicate entries where possible.
Possible matching information can include:
Internal request ID.
URLRequest identity where available.
Timing.
Method.
URL.
Framework metadata.
Deduplication must avoid incorrectly merging unrelated requests.

129. V2.5 — Advanced Diagnostics
Goal
Help developers identify differences between working and failing requests.
Add:
Request comparison.
Response comparison.
JSON diff.
Header diff.
Query diff.
Timing comparison.
Request grouping.
Endpoint grouping.
Host grouping.
Failure grouping.
Session comparison.

130. V3.0 — Team Debugging
Goal
Make network problems easy to share between QA, mobile, and backend teams.
Add:
Diagnostic session bundles.
Session export.
Session import.
Offline session inspection.
Session annotations.
Safe application metadata.
Safe environment metadata.
A QA engineer should be able to:
Start a debug session.
Reproduce a problem.
Stop the session.
Export one package.
Send it to a developer.
The developer should be able to inspect that session without reproducing the issue.

131. V3.5 — Advanced Capture
Goal
Support difficult network environments without increasing V1 complexity.
Add:
Improved background URLSession support.
Streaming-response representation.
Advanced multipart support.
Optional WKWebView support.
fetch observation.
XMLHttpRequest observation.
Custom capture adapters.

132. V4.0 — Extensible Platform
Goal
Provide stable extension points for teams and third-party developers.
Stabilize:
NetworkCaptureAdapter
NetworkStore
NetworkExporter
NetworkSink
NetworkDiagnosticRule
NetworkRedactionRule
NetworkInspectorPlugin

Allow developers to build:
Custom capture adapters.
Custom exporters.
Custom storage.
Custom redaction.
Custom diagnostic rules.
Custom sinks.
Internal integrations.

133. Final Complete Architecture
The complete architecture is:
                         APPLICATION
                              │
                              ▼
                 ┌────────────────────────┐
                 │ NetworkInspector API   │
                 └────────────┬───────────┘
                              │
                              ▼
                 ┌────────────────────────┐
                 │ NetworkInspectorRuntime│
                 └────────────┬───────────┘
                              │
       ┌──────────────────────┼──────────────────────┐
       │                      │                      │
       ▼                      ▼                      ▼
 Capture Adapters       Configuration          Plugin System
       │
       ▼
┌─────────────────────────────────────────────────────┐
│ URLSession                                          │
│ Alamofire                                           │
│ Moya                                                │
│ Apollo                                              │
│ WebKit                                              │
│ Manual                                              │
│ Custom                                              │
└───────────────────────┬─────────────────────────────┘
                        │
                        ▼
                CaptureCoordinator
                        │
                        ▼
              Processing Pipeline
                        │
     ┌──────────────────┼───────────────────┐
     │                  │                   │
  Sampling        Normalization          Privacy
                                          │
                                   Redaction / Limits
                                          │
                                          ▼
                                  Diagnostics Engine
                                          │
                                          ▼
                                    NetworkEntry
                                          │
                                          ▼
                                     Storage
                                          │
                 ┌────────────────────────┼───────────────────────┐
                 │                        │                       │
                 ▼                        ▼                       ▼
             Memory Store             Disk Store            Sessions
                 │                        │                       │
                 └────────────────────────┼───────────────────────┘
                                          │
                                          ▼
                                     Event System
                                          │
                 ┌────────────────────────┼───────────────────────┐
                 │                        │                       │
                 ▼                        ▼                       ▼
           SwiftUI Inspector          Exporters                Sinks
                 │                        │                       │
                 ▼                        ▼                       ▼
            Developer              cURL / JSON / HAR       Custom Tools


134. Final Product Capabilities
The complete product supports:
Capture
URLSession.
Async/await.
Alamofire.
Moya.
Apollo GraphQL.
Uploads.
Downloads.
Multipart.
Background networking where supported.
WKWebView where supported.
Manual capture.
Custom adapters.
Inspection
Requests.
Responses.
Headers.
Query parameters.
Bodies.
Errors.
Sizes.
Timing.
GraphQL information.
Multipart metadata.
Discovery
Search.
Filters.
Quick filters.
Grouping.
Pinning.
Session navigation.
Diagnostics
Failure classification.
Timeout classification.
Slow-request detection.
Timing analysis.
Request comparison.
Response comparison.
Structured diff.
Sessions
Start.
Stop.
Inspect.
Export.
Import.
Compare.
Share.
Export
cURL.
JSON.
HAR.
Custom exporters.
Privacy
Header redaction.
Query redaction.
JSON redaction.
Body limits.
Binary capture policies.
Capture suppression.
Safe export.
Safe persistence.
Extensibility
Capture adapters.
Plugins.
Exporters.
Stores.
Diagnostic rules.
Redaction rules.
Sinks.

135. Non-Goals
Network Inspector is not intended to:
Capture arbitrary raw socket traffic.
Act as a packet analyzer.
Replace Wireshark.
Replace all desktop proxy tools.
Replace Instruments.
Bypass certificate pinning.
Decrypt traffic outside the application network stack.
Capture unsupported traffic without application cooperation.
Store unlimited request bodies.
Become a production analytics service.
Become a production monitoring platform.
Collect user data without explicit application configuration.

136. Technical Success Criteria
Network Inspector succeeds technically when a developer can:
Install the SDK quickly.
Run an application.
Reproduce a network problem.
Open Network Inspector.
Find the failed request.
Inspect what the application sent.
Inspect what the server returned.
Understand the basic failure classification.
Inspect timing information when available.
Reproduce the request with cURL.
Export safe diagnostic information.
Group a reproduction into a debug session.
Share the session with another engineer.
Compare network activity when required.
The normal workflow should not require a desktop proxy.

137. Architecture Success Criteria
The architecture must maintain these rules:
One shared implementation source tree.
One primary public API.
Core does not depend on UI.
Core does not depend on third-party networking frameworks.
Capture does not update UI directly.
Privacy runs before storage.
Raw sensitive data does not enter persistence.
Memory is bounded.
Disk use is bounded.
Application traffic is not modified.
Optional integrations remain optional.
SPM is the primary package system.
CocoaPods uses the same implementation.
V1.0 is useful without later modules.
Later versions extend the basic workflow instead of replacing it.

138. Final Product Principle
Every major technical decision should support this result:
A developer must be able to find, understand, reproduce, compare, and share a network problem without leaving the application.
Network Inspector should not become complex only to support more features.
New features must improve:
Capture.
Understanding.
Diagnosis.
Reproduction.
Comparison.
Sharing.
If a feature does not improve one of these areas, it should not be a priority.