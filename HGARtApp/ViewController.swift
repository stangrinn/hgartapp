import UIKit
import ARKit
import SceneKit
import ReplayKit

class ViewController: UIViewController {

    private var arSceneManager: ARSceneManager!
    private var arCoreManager: ARSceneCoreManager!
    private var sceneView: ARSCNView!
    private var hasPresentedCameraWarning = false
    private var launchLoader: LaunchLoaderView?
    private let launchLoaderShownAt = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showLaunchLoader()
        setupSceneView()
        setupManagers()
        NotificationCenter.default.addObserver(self, selector: #selector(pauseExperience),
            name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resumeExperience),
            name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        resumeExperience()
        presentCameraDeniedIfNeeded()
    }

    private func showLaunchLoader() {
        let loader = LaunchLoaderView(frame: view.bounds)
        loader.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        loader.layer.zPosition = 999
        view.addSubview(loader)
        launchLoader = loader
    }

    private func hideLaunchLoader() {
        launchLoader?.dismiss(minimumVisibleSince: launchLoaderShownAt)
        launchLoader = nil
    }

    private func presentCameraDeniedIfNeeded() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        guard status == .denied || status == .restricted, !hasPresentedCameraWarning else { return }

        hideLaunchLoader()
        let deniedVC = CameraPermissionDeniedViewController()
        deniedVC.modalPresentationStyle = .fullScreen
        present(deniedVC, animated: true, completion: nil)
        hasPresentedCameraWarning = true
    }
    
    private func setupSceneView() {
        
        sceneView = ARSCNView(frame: view.frame)
        
        view.addSubview(sceneView)
        
        sceneView.scene = SCNScene()
        
        sceneView.antialiasingMode = .multisampling4X
        
        sceneView.preferredFramesPerSecond = 60
    }
    
    private func setupManagers() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
       
        if status == .denied || status == .restricted {
            
            presentCameraDeniedIfNeeded()
            
            return
        } else if status == .notDetermined {
            
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if !granted {
                        self.presentCameraDeniedIfNeeded()
                    } else {
                        self.setupManagers()
                    }
                }
            }
            return
        } else {
            
            arSceneManager = ARSceneManager(view: view) // set scene
            
            sceneView.delegate = arSceneManager
            
            arCoreManager = ARSceneCoreManager(sceneView: sceneView)
            
            loadTargets()
            
        }
    }
    
    private func loadTargets() {
        arCoreManager.loadTargetsAndStartARSession { [weak self] result in
            self?.hideLaunchLoader()
            switch result {
            case .success(let loadedTargets):
                self?.arSceneManager.setTargets(loadedTargets)
                if UIApplication.shared.applicationState != .active || self?.view.window == nil {
                    self?.pauseExperience()
                }
            case .failure:
                self?.presentTargetsLoadingFailure()
            }
        }
    }
    
    private func presentTargetsLoadingFailure() {
        guard presentedViewController == nil else { return }
        
        let alert = UIAlertController(title: "Could not load AR content",
                                      message: "Check your internet connection and try again.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.loadTargets()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasPresentedCameraWarning = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        pauseExperience()
    }
    @objc private func pauseExperience() {
        arSceneManager?.setExperienceActive(false)
        sceneView?.session.pause()
    }

    @objc private func resumeExperience() {
        guard isViewLoaded, view.window != nil, UIApplication.shared.applicationState == .active else { return }
        arSceneManager?.setExperienceActive(true)
        if let configuration = sceneView?.session.configuration {
            sceneView.session.run(configuration)
        }
    }

    deinit { NotificationCenter.default.removeObserver(self) }

}

extension ViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        print("ViewController: previewControllerDidFinish")
        dismiss(animated: true, completion: nil)
    }
}
