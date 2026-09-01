import Foundation

public actor CaptureCoordinator {
    private let configurationStore: ConfigurationStore
    private let logStore: LogStore

    private let sampler = CaptureSampler()
    private let normalizer = LogNormalizer()
    private let redactor = RedactionEngine()
    private let truncator = BodyTruncator()
    private let factory = LogEntryFactory()

    public init(configurationStore: ConfigurationStore, logStore: LogStore) {
        self.configurationStore = configurationStore
        self.logStore = logStore
    }

    public func process(_ event: CaptureEvent) async {
        let config = await configurationStore.current()
        guard config.enabledByDefault else { return }
        guard sampler.shouldSample(event: event, config: config) else { return }

        let reqNorm = normalizer.normalizeRequest(event.request)
        let resNorm = normalizer.normalizeResponse(event.response)

        let redactedRequestHeaders = redactor.redactHeaders(reqNorm.headers, redactList: config.redactHeaders)
        let redactedResponseHeaders = resNorm.map { redactor.redactHeaders($0.headers, redactList: config.redactHeaders) }

        let redactedReqBodyData = redactor.redactJSONBodyIfNeeded(reqNorm.body, rules: config.redactBodyKeys)
        let redactedResBodyData = redactor.redactJSONBodyIfNeeded(resNorm?.body, rules: config.redactBodyKeys)

        let reqBodySample = truncator.makeBodySample(
            data: redactedReqBodyData,
            headers: redactedRequestHeaders,
            maxBytes: config.maxBodyBytes,
            captureBinary: config.captureBinaryBodies,
            isRedacted: redactedReqBodyData != reqNorm.body
        )

        let resBodySample = truncator.makeBodySample(
            data: redactedResBodyData,
            headers: redactedResponseHeaders ?? [],
            maxBytes: config.maxBodyBytes,
            captureBinary: config.captureBinaryBodies,
            isRedacted: redactedResBodyData != resNorm?.body
        )

        let reqLog = RequestLog(
            method: event.request.method,
            url: event.request.url,
            headers: redactedRequestHeaders,
            body: reqBodySample,
            bodySize: reqNorm.bodySize
        )

        let resLog: ResponseLog? = {
            guard let resNorm else { return nil }
            return ResponseLog(
                statusCode: event.response?.statusCode,
                headers: redactedResponseHeaders ?? [],
                body: resBodySample,
                bodySize: resNorm.bodySize,
                errorDescription: event.error?.description
            )
        }()

        let flags = LogFlags(
            isRedacted: (redactedReqBodyData != reqNorm.body) || (redactedResBodyData != resNorm?.body),
            isTruncated: (reqBodySample?.isTruncated ?? false) || (resBodySample?.isTruncated ?? false),
            isUpload: false,
            isDownload: false
        )

        let entry = factory.makeLogEntry(
            id: event.id,
            timestamp: event.timestamp,
            source: event.source,
            request: reqLog,
            response: resLog,
            metrics: event.metrics,
            flags: flags,
            tags: event.request.tags
        )

        await logStore.insert(entry)
    }
}