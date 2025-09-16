import XCTest
import ARKit
@testable import HGArt

final class ARSessionManagerTests: XCTestCase {
    var arSessionManager: ARSessionManager!
    var mockSceneView: ARSCNView!
    
    override func setUp() {
        super.setUp()
        mockSceneView = ARSCNView()
        arSessionManager = ARSessionManager(sceneView: mockSceneView)
    }
    
    override func tearDown() {
        arSessionManager = nil
        mockSceneView = nil
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertNotNil(arSessionManager)
    }
} 
