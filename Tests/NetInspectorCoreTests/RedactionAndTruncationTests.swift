import XCTest
@testable import NetInspectorCore

final class RedactionAndTruncationTests: XCTestCase {
    func testHeaderRedaction() {
        let engine = RedactionEngine()
        let headers = [
            Header(name: "Authorization", value: "Bearer secret"),
            Header(name: "Content-Type", value: "application/json")
        ]
        let out = engine.redactHeaders(headers, redactList: ["authorization"])
        XCTAssertEqual(out.first?.value, "REDACTED")
        XCTAssertEqual(out.last?.value, "application/json")
    }

    func testJSONRedactionNested() throws {
        let engine = RedactionEngine()
        let obj: [String: Any] = ["user": ["password": "123", "name": "Ada"]]
        let data = try JSONSerialization.data(withJSONObject: obj, options: [])
        let redacted = engine.redactJSONBodyIfNeeded(data, rules: [.init(.exact("password"))])!
        let json = try JSONSerialization.jsonObject(with: redacted) as! [String: Any]
        let user = json["user"] as! [String: Any]
        XCTAssertEqual(user["password"] as? String, "REDACTED")
        XCTAssertEqual(user["name"] as? String, "Ada")
    }

    func testTruncation() {
        let truncator = BodyTruncator()
        let headers = [Header(name: "Content-Type", value: "application/json")]
        let big = String(repeating: "A", count: 100_000).data(using: .utf8)!
        let sample = truncator.makeBodySample(
            data: big,
            headers: headers,
            maxBytes: 64*1024,
            captureBinary: true,
            isRedacted: false
        )!
        XCTAssertTrue(sample.isTruncated)
        XCTAssertGreaterThan(big.count, sample.preview.utf8.count)
    }
}