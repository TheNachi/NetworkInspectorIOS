import Foundation

public struct JSONRedactionRule: Sendable, Hashable {
    public enum Kind: Hashable {
        case exact(String)
        case regex(String)
    }
    public let kind: Kind

    public init(_ kind: Kind) {
        self.kind = kind
    }
}

public struct SamplingPolicy: Sendable, Hashable {
    public enum Kind: Hashable {
        case all
        case errorsOnly
        case percentage(Double) // 0.0 ... 1.0
    }
    public let kind: Kind

    public init(_ kind: Kind) {
        self.kind = kind
    }
}

public struct Configuration: Sendable, Hashable {
    public var enabledByDefault: Bool
    public var maxEntries: Int
    public var maxBodyBytes: Int
    public var includeTaskMetrics: Bool
    public var captureBinaryBodies: Bool
    public var redactHeaders: [String]
    public var redactBodyKeys: [JSONRedactionRule]
    public var sampling: SamplingPolicy

    public init(
        enabledByDefault: Bool = true,
        maxEntries: Int = 500,
        maxBodyBytes: Int = 64 * 1024,
        includeTaskMetrics: Bool = true,
        captureBinaryBodies: Bool = false,
        redactHeaders: [String] = ["authorization", "cookie", "set-cookie", "x-api-key", "x-auth-token", "proxy-authorization"],
        redactBodyKeys: [JSONRedactionRule] = [
            .init(.exact("password")),
            .init(.exact("otp")),
            .init(.regex(".*token.*"))
        ],
        sampling: SamplingPolicy = .init(.all)
    ) {
        self.enabledByDefault = enabledByDefault
        self.maxEntries = maxEntries
        self.maxBodyBytes = maxBodyBytes
        self.includeTaskMetrics = includeTaskMetrics
        self.captureBinaryBodies = captureBinaryBodies
        self.redactHeaders = redactHeaders
        self.redactBodyKeys = redactBodyKeys
        self.sampling = sampling
    }

    public static var `default`: Configuration { .init() }
}

public actor ConfigurationStore {
    private var configuration: Configuration

    public init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    public func current() -> Configuration { configuration }

    public func update(_ configuration: Configuration) {
        self.configuration = configuration
    }
}