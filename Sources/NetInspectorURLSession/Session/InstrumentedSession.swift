import Foundation

public enum NetInspectorURLSession {
    public static func instrumentedConfiguration(from configuration: URLSessionConfiguration) -> URLSessionConfiguration {
        let cfg = (configuration.copy() as? URLSessionConfiguration) ?? configuration
        var classes = cfg.protocolClasses ?? []
        if classes.contains(where: { $0 == NIURLProtocol.self }) == false {
            classes.insert(NIURLProtocol.self, at: 0)
        }
        cfg.protocolClasses = classes
        return cfg
    }

    public static func makeInstrumentedSession(configuration: URLSessionConfiguration) -> URLSession {
        let cfg = instrumentedConfiguration(from: configuration)
        return URLSession(configuration: cfg)
    }
}