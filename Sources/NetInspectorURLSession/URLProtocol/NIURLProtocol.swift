import Foundation

public final class NIURLProtocol: URLProtocol {
    private static let handledKey = "com.networkinspector.urlprotocol.handled"

    private var task: URLSessionDataTask?

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

        let session = Self.makeNonInterceptingSession()
        task = session.dataTask(with: mutable as URLRequest) { data, response, error in
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