import Foundation
import UIKit
import ARKit
import SceneKit

class ARSceneManager: NSObject, ARSCNViewDelegate {
    
    private var trackedNodes: [UUID: SCNNode] = [:]
    private weak var videoManager: VideoManager?
    private var targets: [ARTarget] = []
    private var scannerOverlay: TargetScannerOverlay!
    
    init(videoManager: VideoManager, scannerOverlay: TargetScannerOverlay) {
        self.videoManager = videoManager
        self.scannerOverlay = scannerOverlay
        super.init()
    }
    
    func setTargets(_ targets: [ARTarget]) {
        print("ARSceneManager: setTargets with count: \(targets.count)")
        self.targets = targets
    }
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let imageAnchor = anchor as? ARImageAnchor else {
            print("ARSceneManager: anchor is not ARImageAnchor")
            return nil
        }
        
        if let node = videoManager?.createOrPlayMainOverlay(for: imageAnchor, targets: targets) {
            print("ARSceneManager: node created for anchor: \(anchor.identifier)")
            trackedNodes[anchor.identifier] = node

            scannerOverlay.hideScanner()
            return node
        }
        
        
        
        print("ARSceneManager: no node created for anchor: \(anchor.identifier)")
        return nil
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else {
            print("ARSceneManager: anchor is not ARImageAnchor")
            return
        }
        
        if !imageAnchor.isTracked {
            videoManager?.setToStartAndPauseVideo(for: anchor.identifier)
            videoManager?.clearCurrentAnchor()
            scannerOverlay.showScanner()
        } else {
            scannerOverlay.hideScanner()
            _ = videoManager?.createOrPlayMainOverlay(for: imageAnchor, targets: targets)
        }
    }
} 
