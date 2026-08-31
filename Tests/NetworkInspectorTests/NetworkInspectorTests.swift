import XCTest
import NetworkInspector

final class NetworkInspectorTests: XCTestCase {
    func testInstallDoesNotCrash() {
        NetworkInspector.install()
        XCTAssertTrue(true)
    }
}