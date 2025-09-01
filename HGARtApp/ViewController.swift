import UIKit
import ARKit
import SceneKit
import ReplayKit

class ViewController: UIViewController {

    private var arSessionManager: ARSessionManager!
    private var videoManager: VideoManager!
    private var recordingManager: RecordingManager!
    private var scannerOverlay: TargetScannerOverlay!
    private var arSceneManager: ARSceneManager!
    private var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSceneView()
        setupManagers()
        setupUI()
    }
    
    private func setupSceneView() {
        
        sceneView = ARSCNView(frame: view.frame)
        view.addSubview(sceneView)
        sceneView.scene = SCNScene()
    }
    
    private func setupManagers() {
        
        videoManager = VideoManager(view: view)
        
        scannerOverlay = TargetScannerOverlay(frame: view.bounds)
        
        view.addSubview(scannerOverlay)
        
        arSceneManager = ARSceneManager(videoManager: videoManager, scannerOverlay: scannerOverlay)
        
        sceneView.delegate = arSceneManager
        
        arSessionManager = ARSessionManager(sceneView: sceneView)
        
        arSessionManager.loadTargetsAndStartSession { [weak self] loadedTargets in
            self?.arSceneManager.setTargets(loadedTargets)
        }
    }
    
    private func setupUI() {
        VideoOverlayManager.createPreloaderOverlay(view: view)
        videoManager.setupControls(view: view)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
