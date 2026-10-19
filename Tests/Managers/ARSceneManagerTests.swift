import XCTest
import ARKit
import SceneKit
import UIKit
@testable import HGArt

final class ARSceneManagerTests: XCTestCase {
    @MainActor
    func testNonImageAnchorDoesNotCreateVideoOverlay() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let manager = ARSceneManager(view: view)
        let anchor = ARAnchor(transform: matrix_identity_float4x4)
        XCTAssertNil(manager.renderer(SCNRenderer(device: nil, options: nil), nodeFor: anchor))
    }
}
