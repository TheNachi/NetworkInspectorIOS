import Foundation
#if canImport(NetInspectorCore)
import NetInspectorCore
#endif

public final class NIURLProtocol: URLProtocol {
    private static let handledKey = "com.networkinspector.urlprotocol.handled"

    private var forwardingTask: URLSessionDataTask?
    private var startTime: Date?
    private var capturedRequestBody: Data?

    public override class func canInit(with request: URLRequest) -> Bool {
        guard let scheme = request.url?.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return false
        }
        if URLProtocol.property(forKey: handledKey, in: request) as? Bool == true {
            return false
        }
        return true
    }

    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    // Support task-based initialization (e.g. for tasks created internally by URLSession)
    public override class func canInit(with task: URLSessionTask) -> Bool {
        guard let request = task.currentRequest else { return false }
        return self.canInit(with: request)
    }

    public override func startLoading() {
        guard let client else { return }

        let mutable = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutable)

        startTime = Date()

        // Capture httpBody and also support httpBodyStream by reading and replacing it
        capturedRequestBody = Self.captureAndPrepareBody(for: mutable)

        let session = Self.makeNonInterceptingSession()
        let reqForTask = mutable as URLRequest

        forwardingTask = session.dataTask(with: reqForTask) { [weak self] data, response, error in
            guard let self else { return }

            if let response {
                client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data {
                client.urlProtocol(self, didLoad: data)
            }
            if let error {
                client.urlProtocol(self, didFailWithError: error)
            } else {
                client.urlProtocolDidFinishLoading(self)
            }

            // Clean up the ad-hoc session
            session.finishTasksAndInvalidate()

            let endTime = Date()
            let startedAt = self.startTime ?? endTime

            let method = (reqForTask.httpMethod ?? self.request.httpMethod) ?? "GET"
            let url = (reqForTask.url ?? self.request.url) ?? URL(string: "about:blank")!

            let reqHeaders = (reqForTask.allHTTPHeaderFields ?? self.request.allHTTPHeaderFields) ?? [:]
            let rawReq = RawRequestCapture(
                method: method,
                url: url,
                headers: reqHeaders,
                body: self.capturedRequestBody,
                tags: [:]
            )

            var rawRes: RawResponseCapture?
            var statusCode: Int?
            var resHeaders: [String: String] = [:]

            if let httpRes = response as? HTTPURLResponse {
                statusCode = httpRes.statusCode
                resHeaders = httpRes.allHeaderFields.reduce(into: [String: String]()) { dict, pair in
                    if let key = pair.key as? String {
                        dict[key] = String(describing: pair.value)
                    } else {
                        dict[String(describing: pair.key)] = String(describing: pair.value)
                    }
                }
            }

            rawRes = RawResponseCapture(
                statusCode: statusCode,
                headers: resHeaders,
                body: data
            )

            let errDesc: CapturedError? = error.map { CapturedError($0.localizedDescription) }

            let metrics = NetworkMetrics(
                startedAt: startedAt,
                endedAt: endTime,
                duration: endTime.timeIntervalSince(startedAt),
                dnsDuration: nil,
                connectionDuration: nil,
                tlsDuration: nil,
                requestDuration: nil,
                responseDuration: nil
            )

            let event = CaptureEvent(
                id: UUID(),
                timestamp: startedAt,
                source: .urlsession,
                request: rawReq,
                response: rawRes,
                error: errDesc,
                metrics: metrics
            )

            Task.detached {
                await GlobalCaptureRouter.shared.submit(event)
            }
        }
        forwardingTask?.resume()
    }

    public override func stopLoading() {
        forwardingTask?.cancel()
        forwardingTask = nil
    }

    private static func makeNonInterceptingSession() -> URLSession {
        let config = URLSessionConfiguration.default
        var classes = config.protocolClasses ?? []
        classes.removeAll { $0 == NIURLProtocol.self }
        config.protocolClasses = classes
        return URLSession(configuration: config)
    }

    // Safely capture body data even when it's provided as a stream
    private static func captureAndPrepareBody(for request: NSMutableURLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else {
            return nil
        }
        let data = readStream(stream)
        // Replace the stream so the downstream request can be sent without consuming a one-shot stream
        request.httpBodyStream = nil
        request.httpBody = data
        return data
    }

    // Helper to read entire InputStream into Data
    private static func readStream(_ stream: InputStream) -> Data? {
        stream.open()
        defer { stream.close() }

        let bufferSize = 64 * 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        var data = Data()
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read < 0 {
                // On error, return whatever we've read so far (or nil if nothing)
                return data.isEmpty ? nil : data
            } else if read == 0 {
                break
            } else {
                data.append(buffer, count: read)
            }
        }
        return data
    }
}