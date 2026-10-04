# Changelog

## 1.0.1
- Packaging: expose only the `NetworkInspector` product to host apps.
- Build: add `macOS(.v12)` to Package platforms and availability guards for CI.
- UI: move quick-filter chips below search; add colored status bar on rows.
- UI: add Close button on inspector and detail screens; align section layouts to design.
- Docs: overhaul README with clear install/usage, examples, and troubleshooting.
- Misc: minor cleanups and consistency updates.

## 1.0.0
- Core pipeline: capture → normalization → redaction → truncation → storage
- URLSession capture via URLProtocol and instrumented session helper
- Manual capture API
- Bounded in-memory storage with event stream
- Diagnostics: basic status classification
- SwiftUI inspector (Requests, Details, Export, Settings)
- Exporters: JSON, cURL
- Safe-by-default in Release, pause/resume, scoped suppression