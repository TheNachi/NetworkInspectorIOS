# Changelog

## 1.0.0
- Core pipeline: capture → normalization → redaction → truncation → storage
- URLSession capture via URLProtocol and instrumented session helper
- Manual capture API
- Bounded in-memory storage with event stream
- Diagnostics: basic status classification
- SwiftUI inspector (Requests, Details, Export, Settings)
- Exporters: JSON, cURL
- Safe-by-default in Release, pause/resume, scoped suppression