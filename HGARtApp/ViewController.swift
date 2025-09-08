import UIKit
import ARKit
import SceneKit
import ReplayKit

class ViewController: UIViewController {

    private var arSessionManager: ARSessionManager!
    private var videoManager: VideoManager!
    private var scannerOverlay: TargetScannerOverlay!
    private var arSceneManager: ARSceneManager!
    private var sceneView: ARSCNView!
    private var hasPresentedCameraWarning = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSceneView()
        setupManagers()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let status = AVCaptureDevice.authorizationStatus(for: .video)

        if (status == .denied || status == .restricted), !hasPresentedCameraWarning {
            let deniedVC = CameraPermissionDeniedViewController()
            deniedVC.modalPresentationStyle = .fullScreen
            present(deniedVC, animated: true, completion: nil)
            hasPresentedCameraWarning = true
        }
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
            let deniedVC = CameraPermissionDeniedViewController()
            deniedVC.modalPresentationStyle = .fullScreen
            present(deniedVC, animated: true, completion: nil)
            return
        } else if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if !granted {
                        let deniedVC = CameraPermissionDeniedViewController()
                        deniedVC.modalPresentationStyle = .fullScreen
                        self.present(deniedVC, animated: true, completion: nil)
                    } else {
                        self.setupManagers()
                    }
                }
            }
            return
        } else {
            videoManager = VideoManager(view: view)
            
            scannerOverlay = TargetScannerOverlay(frame: view.bounds)
            
            view.addSubview(scannerOverlay)
            
            arSceneManager = ARSceneManager(videoManager: videoManager, scannerOverlay: scannerOverlay)
            
            sceneView.delegate = arSceneManager
            
            arSessionManager = ARSessionManager(sceneView: sceneView)
            
            arSessionManager.loadTargetsAndStartSession { [weak self] loadedTargets in
                self?.arSceneManager.setTargets(loadedTargets)
            }
            
            setupUI()
        }
    }
    
    private func setupUI() {
        ARVideoOverlayManager.createPreloaderOverlay(view: view)
        videoManager.setupControls(view: view)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasPresentedCameraWarning = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
}

extension ViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        print("ViewController: previewControllerDidFinish")
        dismiss(animated: true, completion: nil)
    }
}
