import XCTest
import NetworkInspector
import NetInspectorCore

final class CurlExporterTests: XCTestCase {
    func testCurlContainsMethodAndURL() async {
        _ = NetworkInspector.install()
        let url = URL(string: "https://example.com/api")!
        let req = RequestLike(
            method: "POST",
            url: url,
            headers: ["Content-Type":"application/json"],
            body: #"{"a":1}"#.data(using: .utf8)
        )
        NetworkInspector.log(request: req)
        let entries = await NetworkInspector.entries()
        guard let first = entries.first else {
            XCTFail("No entry captured")
            return
        }
        let curl = NetworkInspector.exportCurl(entry: first)
        XCTAssertTrue(curl.contains("curl"))
        XCTAssertTrue(curl.contains("POST"))
        XCTAssertTrue(curl.contains("https://example.com/api"))
    }
}