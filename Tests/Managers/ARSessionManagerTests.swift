import XCTest
@testable import HGArt

final class ARTargetConfigurationTests: XCTestCase {
    func testBundledConfigurationHasUsableTargets() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "ar-config", withExtension: "json"))
        let config = try JSONDecoder().decode(ARTargetsConfig.self, from: Data(contentsOf: url))
        XCTAssertFalse(config.targets.isEmpty)
        XCTAssertEqual(Set(config.targets.map(\.name)).count, config.targets.count)
        for target in config.targets {
            XCTAssertFalse(target.name.isEmpty)
            XCTAssertGreaterThan(target.physicalWidth, 0)
            XCTAssertEqual(URL(string: target.imageUrl)?.scheme, "https")
            XCTAssertEqual(URL(string: target.videoUrl)?.scheme, "https")
        }
    }
}
