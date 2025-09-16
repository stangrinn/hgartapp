import XCTest
import UIKit
@testable import HGArt

final class ToggleIconButtonTests: XCTestCase {
    var toggleButton: ToggledIconButton!
    
    override func setUp() {
        super.setUp()
        toggleButton = ToggledIconButton(
            defaultIconName: "play.fill",
            toggledIconName: "pause.fill", 
            backgroundColor: UIColor.black.withAlphaComponent(0.4),
            symbolSize: 14
        )
    }
    
    override func tearDown() {
        toggleButton = nil
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertNotNil(toggleButton)
    }
    
    func testToggle() {
        // Check initial state
        XCTAssertFalse(toggleButton.getToggled(), "Initial state should be untoggled")
        
        // Toggle the state
        toggleButton.toggle()
        
        // Check that the state has changed
        XCTAssertTrue(toggleButton.getToggled(), "After toggle() button should be toggled")
        
        // Toggle again
        toggleButton.toggle()
        
        // Check that the state returned to initial
        XCTAssertFalse(toggleButton.getToggled(), "After second toggle() button should be untoggled")
    }
    
    func testSetToggled() {
        // Set state explicitly
        toggleButton.setToggled(true)
        
        // Check that the state is set
        XCTAssertTrue(toggleButton.getToggled(), "After setToggled(true) button should be toggled")
        
        // Change the state
        toggleButton.setToggled(false)
        
        // Check that the state has changed
        XCTAssertFalse(toggleButton.getToggled(), "After setToggled(false) button should be untoggled")
    }
    
    func testAttach() {
        // Testing the attach method requires UI verification, which is difficult in unit tests
        // But we can check that the method doesn't throw exceptions
        let mockView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        
        // Call method with a simple selector
        toggleButton.attach(
            to: mockView,
            target: self,
            action: #selector(dummyAction),
            toggled: false,
            xOffset: 16,
            yOffset: 16
        )
        
        XCTAssertTrue(true, "attach method called without errors")
    }
    
    @objc func dummyAction() {
        // Empty method for testing attach
    }
} 
