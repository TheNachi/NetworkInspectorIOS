# NetworkInspector (iOS)

An in-app network debugging and diagnostics SDK for iOS.

- Capture URLSession traffic (including async/await)
- Redact sensitive headers and JSON fields before storage
- Truncate large bodies (64 KB default), skip binary by default
- Inspect requests/responses in-app with a SwiftUI inspector
- Export JSON and cURL (sanitized)
- Bounded in-memory storage, safe-by-default in Release builds

Status: V1.0 core complete (testing toward 1.0.1)


## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+


## Installation (Swift Package Manager)

You only need to add the single product “NetworkInspector”.

Xcode GUI
1) Xcode → File → Add Packages…
2) Enter your repository URL
3) Dependency Rule: Up to Next Major Version (from 1.0.0)
4) In the product picker, set only “NetworkInspector” to your app target (leave others as “None”)
5) Add Package

Package.swift (alternative)
Add this to your app’s Package.swift dependencies and target: