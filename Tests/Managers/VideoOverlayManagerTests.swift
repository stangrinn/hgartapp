import XCTest
import AVFoundation
@testable import HGArt

final class VideoOverlayManagerTests: XCTestCase {
    func testStreamingItemUsesRemoteURLWithoutLocalFile() throws {
        let url = "https://example.com/artwork.mp4?version=2"
        let target = ARTarget(name: "artwork", imageUrl: "https://example.com/image.png", videoUrl: url, physicalWidth: 0.42)
        let item = try XCTUnwrap(ARSceneVideoOverlay().makeStreamingItem(for: target))
        let asset = try XCTUnwrap(item.asset as? AVURLAsset)
        XCTAssertEqual(asset.url.absoluteString, url)
        XCTAssertFalse(asset.url.isFileURL)
        XCTAssertFalse(item.canUseNetworkResourcesForLiveStreamingWhilePaused)
    }

    func testInvalidAndLocalVideoSourcesAreRejected() {
        for url in ["not a URL", "file:///tmp/video.mp4", "http://example.com/video.mp4", "https:///video.mp4"] {
            let target = ARTarget(name: "artwork", imageUrl: "https://example.com/image.png", videoUrl: url, physicalWidth: 0.42)
            XCTAssertNil(ARSceneVideoOverlay().makeStreamingItem(for: target), url)
        }
    }
}
