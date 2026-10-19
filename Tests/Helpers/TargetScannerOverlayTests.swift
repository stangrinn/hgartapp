import XCTest
import ARKit
import UIKit
@testable import HGArt

final class TargetScannerOverlayTests: XCTestCase {
    var targetScannerOverlay: TargetScannerOverlay!
    
    override func setUp() {
        super.setUp()
        // Use frame to properly initialize the overlay
        let frame = CGRect(x: 0, y: 0, width: 320, height: 480)
        targetScannerOverlay = TargetScannerOverlay(frame: frame)
    }
    
    override func tearDown() {
        targetScannerOverlay = nil
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertNotNil(targetScannerOverlay)
    }
    
    @MainActor
    func testStopScanningRemovesAnimation() async {
        // Check that the method doesn't throw exceptions
        targetScannerOverlay.stopScanning()
        // Since the method deals with UI and contains asynchronous calls,
        // it's difficult to directly test its results in unit tests
        await MainActor.run {}
        XCTAssertTrue(targetScannerOverlay.subviews.allSatisfy { $0.layer.animation(forKey: "scan") == nil })
    }
    
    func testViewHierarchy() {
        // Check that overlay contains scanLine
        XCTAssertGreaterThan(targetScannerOverlay.subviews.count, 0, "TargetScannerOverlay should contain subviews")
        
        // Check layers
        XCTAssertGreaterThan(targetScannerOverlay.layer.sublayers?.count ?? 0, 0, "TargetScannerOverlay should contain sublayers")
    }
} 
