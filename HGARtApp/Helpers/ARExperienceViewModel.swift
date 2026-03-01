import Foundation
import Combine

/// ViewModel exposing observable AR experience state and actions for the view controller.
class ARExperienceViewModel {
    // Published properties for UI binding
    @Published var isSessionRunning: Bool = false
    @Published var progress: Double = 0.0
    @Published var errorMessage: String?
    
    // Reference to AR session manager (protocol-based for testability)
    private let arSessionManager: ARSessionManaging
    
    // Any additional dependencies can be injected here
    init(arSessionManager: ARSessionManaging) {
        self.arSessionManager = arSessionManager
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind states from the ARSessionManager to local published properties
        arSessionManager.progressDidUpdate = { [weak self] progress in
            self?.progress = progress
        }
        arSessionManager.didFail = { [weak self] error in
            self?.errorMessage = error.localizedDescription
        }
        arSessionManager.sessionStateDidChange = { [weak self] isRunning in
            self?.isSessionRunning = isRunning
        }
    }
    
    // MARK: - Actions
    func startExperience() {
        arSessionManager.startSession()
    }
    
    func stopExperience() {
        arSessionManager.stopSession()
    }
}
