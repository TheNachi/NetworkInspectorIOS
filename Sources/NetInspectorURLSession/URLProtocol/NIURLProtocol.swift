import Foundation
import NetInspectorCore

public final class NIURLProtocol: URLProtocol {
    private static let handledKey = "com.networkinspector.urlprotocol.handled"

    private var task: URLSessionDataTask?
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

    public override func startLoading() {
        guard let client else { return }

        let mutable = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutable)

        startTime = Date()
        capturedRequestBody = mutable.httpBody

        let session = Self.makeNonInterceptingSession()
        task = session.dataTask(with: mutable as URLRequest) { [weak self] data, response, error in
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

            let endTime = Date()
            let startedAt = self.startTime ?? endTime

            let method = self.request.httpMethod ?? "GET"
            let url = self.request.url ?? URL(string: "about:blank")!

            let reqHeaders = self.request.allHTTPHeaderFields ?? [:]
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
        task?.resume()
    }

    public override func stopLoading() {
        task?.cancel()
        task = nil
    }

    private static func makeNonInterceptingSession() -> URLSession {
        let config = URLSessionConfiguration.default
        var classes = config.protocolClasses ?? []
        classes.removeAll { $0 == NIURLProtocol.self }
        config.protocolClasses = classes
        return URLSession(configuration: config)
    }
}