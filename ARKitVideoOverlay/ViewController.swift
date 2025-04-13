import Foundation
import UIKit
import ARKit
import SceneKit
import SpriteKit
import AVFoundation
import ReplayKit


class ViewController: UIViewController, ARSCNViewDelegate {
    
    var sessionManager: ARSessionManager!
    var targets: [ARTarget] = []
    var referenceImages: Set<ARReferenceImage> = []
    var player: AVPlayer?
    var sceneView: ARSCNView!
    var trackedNodes: [UUID: SCNNode] = [:]
    private var isPlaying = true
    private var isMuted = false
    let recorder = RPScreenRecorder.shared()
    var isRecording = false
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        sceneView = ARSCNView(frame: view.frame)
        
        view.addSubview(sceneView)
        
        VideoOverlayManager.createPreloaderOverlay(view: view)
        
        sessionManager = ARSessionManager(sceneView: sceneView)
        sessionManager.loadTargetsAndStartSession(completion: { [weak self] loadedTargets in
            self?.targets = loadedTargets
            print("Targets loaded: \(loadedTargets)")
        })
        
        print("ARSessionManager loaded successfully")
       
        VideoOverlayManager.setupControls(
            view: self.view,
            target: self,
            playPauseSelector: #selector(togglePlayPause),
            recordSelector: #selector(startStopRecording),
            muteSelector: #selector(toggleMute),
            isMuted: { [weak self] in self?.isMuted ?? false },
            isPlaying: { [weak self] in self?.isPlaying ?? false }
        )
        
        sceneView.delegate = self
        
        sceneView.scene = SCNScene()
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("ViewWill--Appear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        print("ViewWill--Disappear")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        guard let imageAnchor = anchor as? ARImageAnchor else { return nil }
        
        if let existingNode = trackedNodes[anchor.identifier] {
            existingNode.removeFromParentNode()
            trackedNodes.removeValue(forKey: anchor.identifier)
        }
        
        if let result = VideoOverlayManager.createOverlay(for: imageAnchor, targets: targets) {
            
            trackedNodes[anchor.identifier] = result.node
            
            self.player = result.player
            print("Created VIDEO OVERLAY for anchor: \(anchor.identifier)")
            return result.node
        }
                
        return nil
    }
    
        
    @objc private func togglePlayPause() {
        
        guard let player = player else {
            print("Player is nil")
            return
        }
        
        if player.timeControlStatus == .playing {
            player.pause()
            self.isPlaying = false
        } else {
            player.play()
            self.isPlaying = true
        }
        
        VideoOverlayManager.updatePlayPauseIcon(isPlaying: isPlaying)
    }

    @objc private func startStopRecording() {
        if isRecording {
            recorder.stopRecording { previewVC, error in
                self.isRecording = false
                if let error = error {
                    print("Stop recording error: \(error.localizedDescription)")
                    return
                }
                if let previewVC = previewVC {
                    previewVC.previewControllerDelegate = self
                    self.present(previewVC, animated: true, completion: nil)
                }
            }
        } else {
            recorder.startRecording { error in
                if let error = error {
                    print("Start recording error: \(error.localizedDescription)")
                } else {
                    self.isRecording = true
                    print("Recording started")
                }
            }
        }
    }

    @objc private func toggleMute() {
        guard let player = player else { return }
        player.isMuted = !player.isMuted
        self.isMuted.toggle()
        VideoOverlayManager.updateMuteIcon(isMuted: isMuted)
    }
}

extension ViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true, completion: nil)
    }
}
