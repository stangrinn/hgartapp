import UIKit
import AVFoundation
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
        // Use Auto Layout so the scene view always fills the controller's view
        sceneView = ARSCNView(frame: .zero)
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        
        // Ensure the rendering fills the view (prefer fill to avoid letterboxing)
        sceneView.backgroundColor = .black
        // sceneView.contentMode = .scaleAspectFill
        
        view.addSubview(sceneView)
        
         NSLayoutConstraint.activate([
             sceneView.topAnchor.constraint(equalTo: view.topAnchor),
             sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
             sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
             sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
         ])

        sceneView.scene = SCNScene()
    }
    
    private func setupManagers() {
        
        videoManager = VideoManager(view: view)
        
        // Create scanner overlay sized to current bounds and allow it to resize with the view
        scannerOverlay = TargetScannerOverlay(frame: view.bounds)
        scannerOverlay.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scannerOverlay)
        
        NSLayoutConstraint.activate([
            scannerOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            scannerOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scannerOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scannerOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Ensure the camera background scales to fill the view (avoid letterboxing)
        sceneView.layer.contentsGravity = .resizeAspectFill
        sceneView.clipsToBounds = true

        // If a preloader AVPlayerLayer is still present, update its frame and gravity
        view.layer.sublayers?.forEach { layer in
            if let playerLayer = layer as? AVPlayerLayer {
                playerLayer.frame = view.bounds
                playerLayer.videoGravity = .resizeAspectFill
            }
        }
    }
}

extension ViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        print("ViewController: previewControllerDidFinish")
        dismiss(animated: true, completion: nil)
    }
}
