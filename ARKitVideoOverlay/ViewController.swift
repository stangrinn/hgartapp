import Foundation
import UIKit
import ARKit
import SceneKit
import SpriteKit
import AVFoundation
import ReplayKit


class ViewController: UIViewController, ARSCNViewDelegate {
    
    var arSessionManager: ARSessionManager!
    var targets: [ARTarget] = []
    var referenceImages: Set<ARReferenceImage> = []
    var playersByAnchor: [UUID: AVPlayer] = [:]
    var currentAnchorID: UUID?
    var sceneView: ARSCNView!
    var trackedNodes: [UUID: SCNNode] = [:]
    let recorder = RPScreenRecorder.shared()
    var isRecording = false
    private var isPlaying = true
    private var isMuted = false
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        sceneView = ARSCNView(frame: view.frame)
        
        view.addSubview(sceneView)
        
        VideoOverlayManager.createPreloaderOverlay(view: view)
        
        arSessionManager = ARSessionManager(sceneView: sceneView)
        arSessionManager.loadTargetsAndStartSession(completion: { [weak self] loadedTargets in
            self?.targets = loadedTargets
//            print("Targets loaded: \(loadedTargets)")
        })
       
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        guard let imageAnchor = anchor as? ARImageAnchor else { return nil }
        
        playOverlay(for: imageAnchor)
        
        print("Renderer--NodeForAnchor", anchor.identifier, trackedNodes[anchor.identifier] ?? "anchor not found")
        
        return trackedNodes[anchor.identifier]
    }
    
    func renderer(_ renderer: any SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("RENDERER--DidRemove", anchor.identifier)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        
        print ("RENDEERER--DidUpdate", imageAnchor.isTracked)

        if !imageAnchor.isTracked {
            print("Anchor lost: \(anchor.identifier)")

//            if let player = playersByAnchor[anchor.identifier] {
//                player.pause()
//                player.replaceCurrentItem(with: nil)
//                playersByAnchor.removeValue(forKey: anchor.identifier)
//            }
//
//            node.removeFromParentNode()
//            trackedNodes.removeValue(forKey: anchor.identifier)

            if currentAnchorID == anchor.identifier {
                currentAnchorID = nil
            }

            isPlaying = false
            VideoOverlayManager.updatePlayPauseIcon(isPlaying: isPlaying)
        } else {
            playOverlay(for: imageAnchor)
        }
    }
    
    private func playOverlay(for anchor: ARImageAnchor) {
        if let player = playersByAnchor[anchor.identifier] {
            player.seek(to: .zero)
            if player.timeControlStatus != .playing {
                player.play()
                print("▶️ Reused player restarted")
            } else {
                print("⏯ Player already playing")
            }
            isPlaying = true
            VideoOverlayManager.updatePlayPauseIcon(isPlaying: isPlaying)
            return
        }

        if let result = VideoOverlayManager.createOverlay(for: anchor, targets: targets) {
            currentAnchorID = anchor.identifier
            playersByAnchor[anchor.identifier] = result.player
            result.player.seek(to: .zero)
            result.player.play()
            isPlaying = true
            VideoOverlayManager.updatePlayPauseIcon(isPlaying: isPlaying)
            trackedNodes[anchor.identifier] = result.node
            
            print("Created VIDEO OVERLAY for anchor: \(anchor.identifier)")
        }
    }
        
    @objc private func togglePlayPause() {
        
        guard let currentAnchorID = currentAnchorID,
              let player = playersByAnchor[currentAnchorID] else {
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
        guard let currentAnchorID = currentAnchorID,
              let player = playersByAnchor[currentAnchorID] else { return }
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
