import XCTest
@testable import NetInspectorUI

final class NetInspectorUITests: XCTestCase {

    func testUIIsAvailable() {

        XCTAssertTrue(
            NetInspectorUI.isAvailable
        )
    }
}
