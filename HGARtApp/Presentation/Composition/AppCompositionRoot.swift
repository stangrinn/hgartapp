import UIKit

/// Centralized composition point for wiring app screens and dependencies.
enum AppCompositionRoot {
    static func makeRootViewController() -> UIViewController {
        // Transitional setup: keep existing runtime while moving wiring to composition root.
        return ViewController()
    }
}
