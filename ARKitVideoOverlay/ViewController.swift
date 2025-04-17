import UIKit
import ARKit
import SceneKit
import ReplayKit

class ViewController: UIViewController {
    
    private var arSessionManager: ARSessionManager!
    private var videoManager: VideoManager!
    private var recordingManager: RecordingManager!
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
        recordingManager = RecordingManager()
        arSceneManager = ARSceneManager(videoManager: videoManager)
        
        sceneView.delegate = arSceneManager
        
        arSessionManager = ARSessionManager(sceneView: sceneView)
        arSessionManager.loadTargetsAndStartSession { [weak self] loadedTargets in
            self?.arSceneManager.setTargets(loadedTargets)
        }
    }
    
    private func setupUI() {
        VideoOverlayManager.createPreloaderOverlay(view: view)
        
        videoManager.setupControls(
            view: self.view,
            target: self,
            playPauseSelector: #selector(togglePlayPause),
            recordSelector: #selector(startStopRecording),
            muteSelector: #selector(toggleMute)
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    @objc private func togglePlayPause() {
        print("ViewController: togglePlayPause called")
        videoManager.togglePlayPause()
    }
    
    @objc private func startStopRecording() {
        print("ViewController: startStopRecording called, isRecording: \(recordingManager.isRecordingActive)")
        if recordingManager.isRecordingActive {
            recordingManager.stopRecording { [weak self] previewVC, error in
                if let error = error {
                    print("ViewController: Recording stop error: \(error.localizedDescription)")
                }
                if let previewVC = previewVC {
                    previewVC.previewControllerDelegate = self
                    self?.present(previewVC, animated: true, completion: nil)
                }
            }
        } else {
            recordingManager.startRecording { error in
                if let error = error {
                    print("ViewController: Recording start error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func toggleMute() {
        print("ViewController: toggleMute called")
        videoManager.toggleMute()
    }
}

extension ViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        print("ViewController: previewControllerDidFinish")
        dismiss(animated: true, completion: nil)
    }
}
