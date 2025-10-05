import Foundation
import UIKit
import ARKit
import SceneKit

class ARSceneManager: NSObject, ARSCNViewDelegate {
    
    private var trackedNodes: [UUID: SCNNode] = [:]
    private var targets: [ARTarget] = []
    private var videoManager: ARVideoManager!
    private var scannerOverlay: TargetScannerOverlay!
    
    
    init(view: UIView) {
        
        self.videoManager = ARVideoManager(view: view)
        
        self.scannerOverlay = TargetScannerOverlay(frame: view.bounds)
        
        view.addSubview(scannerOverlay)
        
        ARVideoOverlay.createPreloaderOverlay(view: view)
        
        super.init()
    }
    
    func setTargets(_ targets: [ARTarget]) {
        print("ARSceneManager: setTargets with count: \(targets.count)")
        self.targets = targets
    }
    
    // This function calls once when the camera first detects the target
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        print("🎯 CREATE node for anchor: \(anchor.identifier)")
        
        guard let imageAnchor = anchor as? ARImageAnchor else {
            print("ARSceneManager: anchor is not ARImageAnchor")
            return nil
        }
        
        if let node = videoManager.createOrPlayMainOverlay(for: imageAnchor, targets: targets) {
            print("ARSceneManager: node created for anchor: \(anchor.identifier)")
            trackedNodes[anchor.identifier] = node
            scannerOverlay.hideScanner()
            return node
        }
        
        print("ARSceneManager: no node created for anchor: \(anchor.identifier)")
        return nil
    }
    
    // This function calls every frame when the camera tracks the target
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else {
            print("ARSceneManager: anchor is not ARImageAnchor")
            return
        }
        
        if !imageAnchor.isTracked {
            videoManager?.setToStartAndPauseVideo(for: anchor.identifier)
            
            scannerOverlay.showScanner()
        } else {
            scannerOverlay.hideScanner()
//            _ = videoManager?.createOrPlayMainOverlay(for: imageAnchor, targets: targets)
        }
    }
} 
