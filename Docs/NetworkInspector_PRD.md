Network Inspector
Product and Technical Requirements Document
Platform: iOS
Language: Swift
Product Type: Open-source developer SDK
Primary Distribution: Swift Package Manager
License: MIT or Apache 2.0
Document Status: Working Product and Technical Specification

1. Product Overview
Network Inspector is an open-source network debugging SDK for iOS applications.
It lets developers capture, inspect, search, filter, compare, diagnose, and export HTTP and HTTPS network activity from inside an application.
Network Inspector is designed for:
iOS developers.
Mobile engineering teams.
QA engineers.
Backend engineers.
SDK developers.
Distributed development teams.
The SDK provides one inspection interface for network activity from different networking systems.
The first version focuses on URLSession.
Later versions add support for:
Alamofire.
Moya.
Apollo GraphQL.
Multipart requests.
Uploads and downloads.
Background URLSession.
WKWebView.
Custom networking systems.
The SDK must remain modular.
An application must not need every integration to use the core product.

2. Problem
Network debugging on iOS can require several tools.
A developer can need to:
Connect an iPhone or iPad to a Mac.
Open Xcode.
Run a desktop network proxy.
Configure proxy settings.
Install certificates.
Add temporary log statements.
Search console output.
Reproduce a problem.
Reconstruct requests manually.
Send screenshots or copied logs to another engineer.
These steps make debugging slower.
The problem is more difficult for QA and distributed teams.
For example, a QA engineer can find an API failure on a physical device.
The developer can then ask:
What request failed?
What data did the application send?
Which headers did it send?
What did the server return?
How long did the request take?
Was the failure caused by the network?
Was the failure caused by the server?
Can I reproduce the request?
Did another similar request work?
Network Inspector must make these answers available from inside the application.

3. Product Goal
Network Inspector must help a developer:
Find, understand, reproduce, compare, and share a network problem without leaving the application.
This is the primary product goal.
Every major feature must support this goal.

4. Core Product Principles
4.1 Simple Integration
The basic integration must require minimal code.
Example:
NetworkInspector.install()

More configuration must be optional.

4.2 Safe by Default
Network traffic can contain sensitive information.
Network Inspector must protect sensitive information before it stores or exports captured data.
The SDK must be disabled in production Release builds by default.

4.3 Low Runtime Cost
Network Inspector must not significantly change application performance.
The SDK must:
Avoid blocking the main thread.
Limit memory use.
Limit disk use.
Avoid unnecessary body copies.
Avoid unnecessary parsing.
Process large responses safely.

4.4 Modular Design
The Core module must not depend on:
SwiftUI.
Alamofire.
Moya.
Apollo.
WebKit integrations.
Optional integrations must use separate modules.

4.5 Honest Capture
Network Inspector must not claim that it can capture all network traffic.
The SDK must identify capture support as:
Fully supported.
Partially supported.
Manual instrumentation required.
Unsupported.

5. Core Workflow
The normal workflow is:
Application sends request
        ↓
Capture Adapter
        ↓
Normalization
        ↓
Privacy / Redaction
        ↓
Truncation
        ↓
Storage
        ↓
Diagnostics
        ↓
Inspector UI
        ↓
Export / Share

A developer must be able to use this workflow on a physical iPhone or iPad.

6. Core Architecture
The finished architecture consists of the following layers:
Capture Sources
       ↓
Capture Adapters
       ↓
Normalization Pipeline
       ↓
Privacy Pipeline
       ↓
Sampling
       ↓
Truncation
       ↓
Diagnostics Engine
       ↓
Storage
       ↓
Event System
       ↓
┌──────────────┬──────────────┬──────────────┐
│ Inspector UI │  Exporters   │ Plugin APIs  │
└──────────────┴──────────────┴──────────────┘

Capture sources can include:
URLSession
Alamofire
Moya
Apollo GraphQL
WKWebView
Manual Capture
Custom Plugins

All sources must produce the same normalized network model.

7. Package Structure
The final package can contain:
NetworkInspector

├── NetworkInspectorCore
├── NetworkInspectorUI
├── NetworkInspectorURLSession
├── NetworkInspectorDiagnostics
├── NetworkInspectorExporters
├── NetworkInspectorPlugins
│
├── NetworkInspectorAlamofire
├── NetworkInspectorMoya
├── NetworkInspectorApollo
└── NetworkInspectorWebKit

The initial versions do not need all these modules.
The package must grow without breaking the basic integration.

8. Core Data Model
The primary model is NetworkEntry.
Example:
struct NetworkEntry: Identifiable, Codable, Sendable {

    let id: UUID
    let createdAt: Date

    let source: NetworkSource

    let request: NetworkRequest
    let response: NetworkResponse?

    let metrics: NetworkMetrics?
    let diagnostics: NetworkDiagnostics?

    let flags: NetworkFlags

    var tags: [String: String]
    var note: String?
}

The model should be immutable where practical.

9. Network Request
A request can contain:
ID.
HTTP method.
Full URL.
Scheme.
Host.
Path.
Query parameters.
Headers.
Content type.
Body sample.
Actual body size.
Captured body size.
Timestamp.

10. Network Response
A response can contain:
HTTP status code.
Headers.
Content type.
Body sample.
Actual body size.
Captured body size.
Error.
Timestamp.

11. Network Metrics
When available, metrics can contain:
Start time.
End time.
Total duration.
DNS duration.
Connection duration.
TLS duration.
Request duration.
Server wait duration.
Response duration.
Redirect count.
The SDK must distinguish:
Exact.
Estimated.
Unknown.
The UI must not show estimated information as exact information.

12. Privacy
Privacy processing must occur before persistent storage or external export.
Default protected headers include:
Authorization
Cookie
Set-Cookie
X-API-Key
X-Auth-Token
Proxy-Authorization

Default protected body fields include:
password
token
secret
otp
pin
access_token
refresh_token

Header matching must not depend on letter case.
Applications must be able to define custom rules.
Example:
.redactBodyKeys([
    .exact("password"),
    .exact("otp"),
    .regex(".*token.*")
])

Applications must also be able to stop capture temporarily.
Example:
NetworkInspector.pause()

NetworkInspector.resume()

A scoped API should also exist:
NetworkInspector.withLoggingDisabled {
    // Sensitive operation
}


13. Body Capture
The SDK must limit stored body data.
Recommended default:
64 KB

The SDK must preserve the difference between:
Actual Body Size:    4.2 MB
Captured Body Size: 64 KB

Binary bodies must not be captured by default.
Possible policies are:
.captureNone
.captureMetadataOnly
.captureText
.captureSample(maxBytes:)


14. Storage
Memory
The first storage system is a bounded in-memory store.
Recommended default:
500 entries

The oldest entry is removed when the limit is reached.
A ring buffer is preferred.
Disk
Later versions add optional persistent storage.
The storage system must support:
Maximum disk size.
Retention period.
Background writes.
Batched writes.
Automatic eviction.
Clear on demand.
Persistent storage must remain optional.

15. Inspector Interface
The main interface contains:
Network Inspector

Search...

[All] [Failed] [4xx] [5xx] [Slow]

────────────────────────────

POST /v1/checkout
422 • 842 ms • 486 B

GET /v1/products
200 • 214 ms • 42 KB

POST /v1/login
401 • 190 ms • 1.1 KB

Each row must make the request state easy to identify.

16. Request Details
The request detail screen can contain:
Summary

Request

Response

Headers

Body

Query Parameters

Timing

Diagnostics

Tags

Notes

Each useful value must support copy actions.

17. Diagnostics
Network Inspector must do more than record requests.
It must help the developer understand them.
The diagnostics system can classify:
Success
Redirect
Client Error
Server Error
Network Failure
Timeout
Cancelled
Slow Request
No Response

For example:
POST /checkout

Status
422 Client Error

Duration
842 ms

Possible Cause
Server rejected the request.

Response Error
delivery_address is required

The SDK must not invent a cause when the available information does not support one.

18. Search
Search can include:
URL.
Host.
Path.
HTTP method.
Status.
GraphQL operation.
Tags.
Notes.
Sensitive body search must be disabled by default.

19. Filters
Filters can include:
HTTP method.
Status code.
Status range.
Host.
Path.
Source.
Time.
Error state.
Upload.
Download.
Request body.
Response body.
Redacted.
Tagged.
Slow request.
Quick filters should include:
All
Failed
4xx
5xx
Slow
Uploads
Downloads


20. Debug Sessions
A debug session groups requests for one debugging task.
Example:
Session

Checkout Failure

Started       14:32
Duration      2m 14s
Requests      27
Failures      3

POST /cart             200
POST /promo            200
POST /checkout         422
GET  /orders           200

A user can:
Start a session.
Reproduce a problem.
Stop the session.
Review the requests.
Export the session.
Share the session.
Optional session metadata can include:
Application version.
Build number.
iOS version.
Device model.
Environment.
Session start.
Session end.
Sensitive device identifiers must not be collected.

21. Export
Network Inspector must support multiple export formats.
cURL
A developer can convert a captured request to a cURL command.
Removed secrets must remain removed.
JSON
The SDK must provide its own structured export format.
This format can represent:
Individual requests.
Multiple requests.
Debug sessions.
Diagnostics.
Metrics.
HAR
Later versions must support HAR 1.2 where captured information is sufficient.

22. Request Comparison
Later versions must allow developers to compare requests.
Example:
Compare Requests

                 Request A       Request B

Status           200             422
Duration         410 ms          690 ms
Environment      Staging         Production

Changed Request Data

addressId        "123"           Missing
promoCode        "SAVE20"        "SAVE20"

Comparison can include:
URL.
Query parameters.
Headers.
Request bodies.
Response bodies.
Status.
Timing.
Environment.
Sensitive fields must remain protected.

23. URLSession Support
URLSession is the primary capture system.
The SDK should support:
Data tasks.
Async/await.
Combine URLSession usage.
Upload tasks.
Download tasks.
Redirects.
Errors.
URLSessionTaskMetrics.
A custom URLProtocol can provide the primary interception mechanism.
The SDK must also support explicit instrumented sessions.
Example:
let session = NetworkInspector.makeInstrumentedSession(
    configuration: .default
)

The SDK must prevent recursive interception.

24. Manual Capture
Custom networking systems must have a manual API.
Example:
NetworkInspector.log(
    request: request,
    response: response,
    error: error,
    metrics: metrics
)

Manual entries must use the same:
Data model.
Privacy pipeline.
Storage.
Search.
Filters.
Diagnostics.
Export system.

25. Alamofire
A later version must provide first-class Alamofire integration.
It can support:
NetworkInspector.makeInstrumentedAlamofireSession()

It can also provide an EventMonitor.
Framework-specific information can be added as metadata.

26. Moya
Moya integration can provide:
NetworkInspector.makeMoyaPlugin()

It can capture:
Target metadata.
Generated URLRequest.
Response.
Error.
Timing information.

27. Apollo GraphQL
Apollo integration must understand GraphQL concepts.
It can capture:
Operation name.
Operation type.
Variables.
HTTP request.
HTTP response.
GraphQL errors.
Network errors.
The UI can display:
GraphQL

Operation
CreateOrder

Type
Mutation

HTTP Status
200

GraphQL Errors
1

GraphQL variables must use the standard privacy pipeline.

28. Multipart Requests
Multipart inspection must focus on metadata.
Default capture can include:
Boundary information.
Total size.
Part name.
MIME type.
Part size.
Binary data must remain disabled by default.

29. Uploads and Downloads
Uploads must show:
Request.
Content type.
Upload size.
Response.
Duration.
Error.
Downloads must show:
Request.
Status.
Expected size.
Downloaded size.
Duration.
Error.
Downloaded file contents must not be stored by default.

30. Background Networking
Background URLSession has platform limitations.
Network Inspector must not promise complete automatic interception.
The SDK can provide:
Compatible session helpers.
Delegate instrumentation.
Manual completion logging.
Documentation must clearly state the supported behavior.

31. WKWebView
WKWebView support is an optional advanced plugin.
It can observe:
fetch.
XMLHttpRequest.
JavaScript events can pass through WKScriptMessageHandler.
This feature must be:
Optional.
Disabled by default.
Isolated from Core.
Clearly documented.
WKWebView support is not required for the initial stable release.

32. Presentation
The inspector can support:
NetworkInspector.present(from: viewController)

and:
NetworkInspectorView()

Later presentation options can include:
Shake gesture.
Triple tap.
Custom gesture.
Deep link.
Floating button.
The explicit API must remain available.

33. Concurrency
Core must be safe during concurrent network activity.
A recommended architecture is:
Capture
   ↓
Background Processing
   ↓
Storage Actor
   ↓
Event Stream
   ↓
MainActor UI

MainActor must only be used where UI isolation is required.
Models should conform to Sendable where practical.

34. Performance Requirements
Network Inspector must:
Never block the main thread for capture processing.
Keep memory bounded.
Keep storage bounded.
Parse bodies lazily where possible.
Apply capture policies early.
Avoid unnecessary Data copies.
Batch disk operations.
Stop expensive processing when disabled.
Performance tests must measure:
CPU overhead.
Memory overhead.
Requests per second.
Large body behavior.
Concurrent request behavior.
Disk growth.
UI update performance.

35. Testing
Unit Tests
Test:
Capture.
Normalization.
Redaction.
Truncation.
Sampling.
Size calculation.
Diagnostics.
Search.
Filters.
Exporters.
Integration Tests
Test:
URLSession.
Async/await.
Uploads.
Downloads.
Alamofire.
Moya.
Apollo.
Multipart.
UI Tests
Test:
Request list.
Search.
Filters.
Details.
Empty states.
Error states.
Large bodies.
Debug sessions.
Comparison.
Performance Tests
Test:
High request volume.
Large responses.
Concurrent requests.
Rapid UI updates.
Memory pressure.
Disk limits.

36. Build Safety
Development builds can enable Network Inspector.
Release builds must disable it by default.
Explicit configuration must be required for:
Ad Hoc builds.
TestFlight builds.
Internal diagnostic builds.
The SDK must never silently enable itself in production.

37. Version 1.0 — Core Network Inspector
Version 1.0 must solve the primary network debugging problem.
It includes:
Capture
URLSession capture.
Data tasks.
Async/await.
Basic upload and download metadata.
Manual capture.
Inspection
Request list.
Request details.
Response details.
Headers.
Query parameters.
Text bodies.
Errors.
Basic timing.
Discovery
Search.
HTTP method filters.
Status filters.
Host filters.
Error filters.
Privacy
Header redaction.
JSON field redaction.
Body limits.
Binary bodies disabled by default.
Release builds disabled by default.
Storage
Bounded in-memory storage.
Export
Copy cURL.
JSON export.
Diagnostics
Success.
Redirect.
Client error.
Server error.
Network failure.
Timeout.
Cancelled.
Sessions
Start debug session.
Stop debug session.
Export debug session.
Version 1.0 must already be useful as a standalone product.

38. Version 1.5 — Professional Inspection
Version 1.5 improves the daily debugging workflow.
Add:
URLSessionTaskMetrics.
Detailed timing.
Slow-request detection.
Advanced search.
Advanced filters.
Disk persistence.
Retention policies.
HAR export.
Tags.
Notes.
Session metadata.
Improved body viewer.
JSON formatting.
Form-data formatting.
Better multipart metadata.
Request pinning.
The goal is to make Network Inspector useful during normal daily development.

39. Version 2.0 — Networking Ecosystem
Version 2.0 expands capture support.
Add first-class integrations for:
Alamofire.
Moya.
Apollo GraphQL.
Add:
GraphQL operation inspection.
GraphQL error inspection.
Better upload inspection.
Better download inspection.
Capture-source indicators.
Event deduplication.
Plugin APIs.
Applications that use several networking libraries must see all supported requests in one inspector.

40. Version 2.5 — Advanced Diagnostics
Version 2.5 changes Network Inspector from an inspector into a stronger diagnostic tool.
Add:
Request comparison.
Response comparison.
Structured JSON diff.
Header diff.
Query parameter diff.
Timing comparison.
Session comparison.
Environment labels.
Failure summaries.
Request grouping.
Endpoint grouping.
Host grouping.
Error grouping.
The SDK must help developers identify what changed between working and failing requests.

41. Version 3.0 — Team Debugging
Version 3.0 improves workflows between developers, QA engineers, and backend engineers.
Add:
Rich debug-session bundles.
Session import.
Session export.
Offline session inspection.
Shareable diagnostic packages.
Application metadata.
Environment metadata.
Custom session metadata.
Session annotations.
A QA engineer must be able to reproduce a problem and send one safe diagnostic package to a developer.
A developer must be able to open that package and inspect the captured session.

42. Version 3.5 — Advanced Capture
Version 3.5 adds difficult capture scenarios.
Add:
Better background URLSession support.
Streaming-response representation.
Advanced multipart support.
Optional WKWebView plugin.
fetch inspection.
XMLHttpRequest inspection.
Custom capture adapters.
These features must remain optional.

43. Version 4.0 — Extensible Platform
Version 4.0 makes Network Inspector an extensible debugging platform.
Provide stable public protocols for:
CaptureAdapter
NetworkStore
NetworkExporter
NetworkSink
DiagnosticRule
RedactionRule
NetworkInspectorPlugin

Developers can build custom:
Capture integrations.
Export formats.
Storage systems.
Diagnostic rules.
UI extensions.
Internal tooling integrations.
Core must remain independent of these implementations.

44. Complete Product
The complete Network Inspector product provides:
Capture
URLSession.
Async/await.
Alamofire.
Moya.
Apollo.
Uploads.
Downloads.
Multipart.
Background networking where supported.
WKWebView where supported.
Manual networking.
Custom capture plugins.
Inspection
Requests.
Responses.
Headers.
Query parameters.
Bodies.
Errors.
Sizes.
Timing.
GraphQL operations.
Multipart metadata.
Discovery
Search.
Filters.
Quick filters.
Grouping.
Tags.
Notes.
Pinning.
Diagnostics
Failure classification.
Slow-request detection.
Timing analysis.
Request comparison.
Response comparison.
Structured differences.
Sessions
Start session.
Stop session.
Inspect session.
Compare sessions.
Export session.
Import session.
Share session.
Export
cURL.
JSON.
HAR.
Custom exporters.
Privacy
Header redaction.
Body-field redaction.
Custom rules.
Body limits.
Binary policies.
Capture suppression.
Safe export.
Safe persistence.
Extensibility
Capture adapters.
Plugins.
Exporters.
Storage providers.
Diagnostic rules.
External sinks.

45. Final Architecture
The completed architecture is:
                   Network Sources

 URLSession   Alamofire   Moya   Apollo   WebKit   Custom
      │           │        │       │        │        │
      └───────────┴────────┴───────┴────────┴────────┘
                              │
                       Capture Adapters
                              │
                              ▼
                        Normalization
                              │
                              ▼
                      Privacy / Redaction
                              │
                              ▼
                    Sampling / Truncation
                              │
                              ▼
                      Diagnostics Engine
                              │
                              ▼
                         Storage Actor
                              │
                  ┌───────────┴───────────┐
                  │                       │
               Memory                  Disk
                  │                       │
                  └───────────┬───────────┘
                              │
                         Event System
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
          ▼                   ▼                   ▼
    Inspector UI          Exporters            Plugins
          │                   │                   │
          ▼                   ▼                   ▼
       Developer        cURL / HAR / JSON    Custom Tools


46. Internal Project Structure
A mature repository can use:
Sources/
│
├── NetworkInspectorCore/
│   │
│   ├── Capture/
│   ├── Models/
│   ├── Processing/
│   ├── Privacy/
│   ├── Storage/
│   ├── Events/
│   ├── Sessions/
│   └── Configuration/
│
├── NetworkInspectorDiagnostics/
│   │
│   ├── Rules/
│   ├── Classification/
│   ├── Comparison/
│   └── Analysis/
│
├── NetworkInspectorURLSession/
│   │
│   ├── URLProtocol/
│   ├── Metrics/
│   ├── Uploads/
│   └── Downloads/
│
├── NetworkInspectorUI/
│   │
│   ├── RequestList/
│   ├── RequestDetails/
│   ├── Search/
│   ├── Filters/
│   ├── Sessions/
│   ├── Comparison/
│   └── Components/
│
├── NetworkInspectorExporters/
│   │
│   ├── Curl/
│   ├── JSON/
│   └── HAR/
│
├── NetworkInspectorAlamofire/
├── NetworkInspectorMoya/
├── NetworkInspectorApollo/
├── NetworkInspectorWebKit/
│
└── NetworkInspectorPlugins/

Tests should follow the same module boundaries.

47. Version Strategy
The project must not wait until Version 4.0 to become useful.
Each major release must solve a complete problem.
V1.0
Capture and understand requests
        ↓
V1.5
Inspect requests efficiently
        ↓
V2.0
Support the wider iOS networking ecosystem
        ↓
V2.5
Diagnose and compare problems
        ↓
V3.0
Share debugging sessions across teams
        ↓
V3.5
Support difficult capture scenarios
        ↓
V4.0
Become an extensible debugging platform

Version 1.0 is the foundation.
Later releases increase capability without changing the basic product model.

48. Success Criteria
Network Inspector succeeds when an iOS developer can:
Add the SDK quickly.
Run the application.
Reproduce a network problem.
Open Network Inspector.
Find the failed request.
Understand what happened.
Inspect the request and response.
Reproduce the request with cURL.
Compare it with another request when necessary.
Export the debugging session.
Share safe diagnostic information with another engineer.
The developer should not need a desktop proxy for this normal workflow.

49. Non-Goals
Network Inspector is not intended to:
Capture arbitrary raw socket traffic.
Act as a packet analyzer.
Replace Wireshark.
Replace Instruments.
Replace all desktop proxy tools.
Decrypt traffic outside the application networking stack.
Bypass certificate pinning.
Capture unsupported traffic without application cooperation.
Store unlimited request bodies.
Become a production analytics platform.
Become a production user-monitoring system.
These boundaries must remain clear.

50. Final Product Statement
Network Inspector is an open-source iOS network debugging and diagnostics SDK.
It gives developers one place to capture, inspect, search, filter, diagnose, compare, reproduce, export, and share application network activity.
The product starts with a focused URLSession inspector.
It grows into a unified inspection system for the main iOS networking approaches.
The completed product supports individual developers, QA teams, mobile teams, backend teams, and custom developer tooling.
The architecture prioritizes:
Simple integration.
Safe defaults.
Privacy.
Low runtime cost.
Clear diagnostics.
Modular design.
Extensibility.
Native iOS development workflows.
The primary product promise remains:
Find, understand, reproduce, compare, and share a network problem without leaving the application.