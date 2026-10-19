import XCTest
@testable import HGArt

final class HGARtTests: XCTestCase {
    func testTargetDecodingPreservesPhysicalWidth() throws {
        let data = Data(#"{"name":"test","imageUrl":"https://example.com/image.png","videoUrl":"https://example.com/video.mp4","physicalWidth":0.42}"#.utf8)
        let target = try JSONDecoder().decode(ARTarget.self, from: data)
        XCTAssertEqual(target.name, "test")
        XCTAssertEqual(target.physicalWidth, 0.42, accuracy: 0.0001)
    }
}
