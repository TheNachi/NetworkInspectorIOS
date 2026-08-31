import XCTest
import NetInspectorPlugins

final class NetInspectorPluginsTests: XCTestCase {
    func testPluginsModuleAvailable() {
        XCTAssertTrue(NetInspectorPlugins.isAvailable)
    }
}