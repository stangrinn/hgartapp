import XCTest
import AVFoundation
@testable import HGArt

final class PlayerObserverTests: XCTestCase {
    var playerObserver: PlayerObserver!
    var mockPlayer: AVPlayer!
    var mockItem: AVPlayerItem!
    
    override func setUp() {
        super.setUp()
        // Create a test AVPlayerItem with a dummy URL
        let testURL = URL(string: "https://example.com/test.mp4")!
        mockItem = AVPlayerItem(url: testURL)
        mockPlayer = AVPlayer(playerItem: mockItem)
        playerObserver = PlayerObserver(player: mockPlayer)
    }
    
    override func tearDown() {
        playerObserver = nil
        mockPlayer = nil
        mockItem = nil
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertNotNil(playerObserver)
        XCTAssertNotNil(playerObserver.player)
        XCTAssertEqual(playerObserver.player, mockPlayer)
    }
    
}

private final class ReadyPlayerItem: AVPlayerItem {
    override var status: AVPlayerItem.Status { .readyToPlay }
}

private final class PlaybackSpy: AVPlayer {
    var playCalls = 0
    override func play() { playCalls += 1 }
}

extension PlayerObserverTests {
    func testReadyNotificationDoesNotBypassTrackingAndStartPlayback() {
        let player = PlaybackSpy()
        let observer = PlayerObserver(player: player)
        let item = ReadyPlayerItem(asset: AVMutableComposition())
        observer.observeValue(forKeyPath: "status", of: item, change: nil, context: nil)
        XCTAssertEqual(player.playCalls, 0)
    }
}
