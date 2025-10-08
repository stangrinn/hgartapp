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
        
        print("🚀 Initializing ARSceneManager")
        
        self.videoManager = ARVideoManager(view: view)
        
        self.scannerOverlay = TargetScannerOverlay(frame: view.bounds)
        
        view.addSubview(scannerOverlay)
        
        AppPreloaderOverlay.run(view: view)
        
        super.init()
    }
    
    func setTargets(_ targets: [ARTarget]) {
        print("ARSceneManager: setTargets with count: \(targets.count)")
        
        self.targets = targets
    }
    
    // This function calls once when the camera first detects the target
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        print("✅ 1 ARSceneManager: RENDER TRY CREATE node for anchor: \(anchor)")
        
        guard let imageAnchor = anchor as? ARImageAnchor else {
            print("💩 1 ARSceneManager: anchor is not ARImageAnchor")
            return nil
        }

        // If sync didn't work, try async with caching
        let parentNode = SCNNode()
        
        trackedNodes[anchor.identifier] = parentNode
        
        Task {
            await videoManager.createOverlayVideoPlaneAsync(
                for: imageAnchor,
                targets: targets,
                parentNode: parentNode
            )
            
            await MainActor.run {
//                scannerOverlay.hideScanner()
                print("✅ 1 ARSceneManager: async node CREATED for anchor: \(anchor.identifier)")
            }
        }
        
        print("✅ 1 ARSceneManager: async loading started for anchor: \(anchor.identifier)")
        
        return parentNode
    }
    
    // This function calls every frame when the camera tracks the target 60fps
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let imageAnchor = anchor as? ARImageAnchor else {
            print("💩 ∞ ARSceneManager: anchor is not ARImageAnchor")
            
            return
        }
        
        if !imageAnchor.isTracked {
            videoManager.stopVideo(for: anchor.identifier)
            
            scannerOverlay.showScanner()
            
//            print("✅ ∞ ARSceneManager: anchor is NOT TRACKED")
            
        } else {
            
            videoManager.startVideo(for: anchor.identifier)
            
            scannerOverlay.hideScanner()
            
//            print("✅ ∞ ARSceneManager: anchor is TRACKED")
        }
    }
} 
