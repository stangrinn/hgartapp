import UIKit

/// Coordinator handles navigation and flow for the AR experience.
class ARExperienceCoordinator {
    let navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let arSessionManager = ARSessionManager()
        
        let viewModel = ARExperienceViewModel(arSessionManager: arSessionManager)
        
        let vc = ARExperienceViewController(viewModel: viewModel)
        
        navigationController.setViewControllers([vc], animated: false)
    }
}
