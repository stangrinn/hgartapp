import XCTest
import AVFoundation
import ARKit
import SceneKit
import UIKit
@testable import HGArt

private final class RecordingPlayer: AVQueuePlayer {
    var playCalls = 0
    var pauseCalls = 0
    override func play() { playCalls += 1 }
    override func pause() { pauseCalls += 1 }
}

@MainActor
private final class DelayedVideo {
    let player = RecordingPlayer()
    var started: (() -> Void)?
    var pending: CheckedContinuation<AVQueuePlayer?, Never>?

    func load() async -> AVQueuePlayer? {
        await withCheckedContinuation { continuation in
            pending = continuation
            started?()
        }
    }

    func finish() {
        pending?.resume(returning: player)
        pending = nil
    }
}

final class VideoManagerTests: XCTestCase {
    @MainActor
    func testLossDuringDownloadDoesNotStartPlaybackAndReacquisitionResumes() async throws {
        let overlay = DelayedVideo()
        let view = UIView()
        let manager = ARSceneVideoManager(view: view)
        let anchorID = UUID()
        let started = expectation(description: "Download started")
        overlay.started = { started.fulfill() }
        manager.updateTracking(true, for: anchorID)
        let load = Task {
            await manager.prepareVideo(for: anchorID) { await overlay.load() }
        }
        await fulfillment(of: [started], timeout: 3)
        manager.updateTracking(false, for: anchorID)
        manager.stopVideo(for: anchorID)
        overlay.finish()
        let loaded = await load.value
        XCTAssertTrue(loaded)
        XCTAssertEqual(overlay.player.playCalls, 0, "A late download must not start a lost anchor")

        manager.updateTracking(true, for: anchorID)
        manager.startVideo(for: anchorID)
        XCTAssertEqual(overlay.player.playCalls, 1)
        XCTAssertTrue(overlay.player.isMuted)
    }

    @MainActor
    func testDownloadStartsPlaybackWhenAnchorRemainsTracked() async {
        let overlay = DelayedVideo()
        let view = UIView()
        let manager = ARSceneVideoManager(view: view)
        let anchorID = UUID()
        let started = expectation(description: "Download started")
        overlay.started = { started.fulfill() }
        manager.updateTracking(true, for: anchorID)
        let load = Task {
            await manager.prepareVideo(for: anchorID) { await overlay.load() }
        }
        await fulfillment(of: [started], timeout: 3)
        overlay.finish()
        _ = await load.value
        XCTAssertEqual(overlay.player.playCalls, 1)
        manager.updateTracking(false, for: anchorID)
        manager.stopVideo(for: anchorID)
        manager.startVideo(for: anchorID)
        XCTAssertEqual(overlay.player.playCalls, 1, "A stale start callback must not restart a lost anchor")
        XCTAssertGreaterThan(overlay.player.pauseCalls, 0)
    }

}
