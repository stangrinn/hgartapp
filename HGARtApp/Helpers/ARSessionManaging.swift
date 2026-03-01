import Foundation

/// Protocol abstracting ARKit/SceneKit session management.
protocol ARSessionManaging: AnyObject {
    // Callbacks for view model binding
    var progressDidUpdate: ((Double) -> Void)? { get set }
    var didFail: ((Error) -> Void)? { get set }
    var sessionStateDidChange: ((Bool) -> Void)? { get set }

    // Actions
    func startSession()
    func stopSession()
}

/// Example stub implementation for development/testing.
class ARSessionManager: ARSessionManaging {
    var progressDidUpdate: ((Double) -> Void)?
    var didFail: ((Error) -> Void)?
    var sessionStateDidChange: ((Bool) -> Void)?

    func startSession() {
        // Start ARKit/SceneKit session and call sessionStateDidChange
        sessionStateDidChange?(true)
        // Simulate progress
        progressDidUpdate?(0.1)
    }

    func stopSession() {
        // Stop ARKit/SceneKit session
        sessionStateDidChange?(false)
    }
}
