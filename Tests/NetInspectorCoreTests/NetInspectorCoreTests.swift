import XCTest
@testable import NetInspectorCore

final class NetInspectorCoreTests: XCTestCase {

    func testVersionExists() {

        XCTAssertEqual(
            NetInspectorCore.version,
            "0.1.0"
        )
    }
}
