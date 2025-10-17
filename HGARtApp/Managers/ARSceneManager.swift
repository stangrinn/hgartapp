import Foundation
import UIKit
import ARKit
import SceneKit
import SpriteKit

class ARSceneManager: NSObject, ARSCNViewDelegate {
    
    private var trackedNodes: [UUID: SCNNode] = [:]
    
    private var targets: [ARTarget] = []
    
    private var videoManager: ARSceneVideoManager!
    
    private var scannerOverlay: TargetScannerOverlay!
    
    private var appPreloaderOverlay: AppPreloaderOverlay!
    
    // Debounce tracking start/stop to avoid thrashing
    private var startWorkItems: [UUID: DispatchWorkItem] = [:]
    private var stopWorkItems: [UUID: DispatchWorkItem] = [:]
    
    init(view: UIView) {
        
        print("🚀 Initializing ARSceneManager")
        
        self.appPreloaderOverlay = AppPreloaderOverlay(view: view)
        
        self.videoManager = ARSceneVideoManager(view: view)
        
        self.scannerOverlay = TargetScannerOverlay(frame: view.bounds)
        
        view.addSubview(scannerOverlay)
        
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
        
        let parentNode = SCNNode()
        
        trackedNodes[anchor.identifier] = parentNode
        
        // Create placeholder plane immediately
        let padding: CGFloat = 0.01
        
        let width = imageAnchor.referenceImage.physicalSize.width * (1.0 + padding)
        
        let height = imageAnchor.referenceImage.physicalSize.height * (1.0 + padding)
        
        let plane = SCNPlane(width: width, height: height)
        
        // Pass actual physical dimensions to PreloaderScene for correct proportions
        let ps = PreloaderScene(anchorID: anchor.identifier, width: width, height: height)
        
        var preScene: SKScene!
        
        DispatchQueue.main.sync { preScene = ps.getScene() }
        
        plane.firstMaterial?.diffuse.contents = preScene
        
//        print("🎨 Preloader scene assigned to material: \(preScene!)")
        
        // No transform - let PreloaderScene handle flipping internally
        plane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Identity
        
        plane.firstMaterial?.isDoubleSided = true
        
        plane.firstMaterial?.lightingModel = .constant
        
        let planeNode = SCNNode(geometry: plane)
        
        planeNode.renderingOrder = 2000
        
        // Standard rotation to align with image anchor
        planeNode.eulerAngles.x = -.pi / 2
        
        parentNode.addChildNode(planeNode)
        
//        print("📦 Placeholder node created and added immediately")
        
        // Load video asynchronously and update the plane
        Task {
            let ok = await videoManager.createOverlayVideoPlaneAsync(
                for: imageAnchor,
                targets: targets,
                parentNode: parentNode,
                onProgress: { [weak ps] progress in
                    ps?.updatePreloaderProgress(for: anchor.identifier, progress: progress)
                }
            )
            
            await MainActor.run {
                if ok {
                    // success: hide scanner and optionally fade preloader
                    ps.fadeOutPreloader(for: anchor.identifier)
                    self.scannerOverlay.hideScanner()
                    print("✅ 1 ARSceneManager: async video loaded for anchor: \(anchor.identifier)")
                } else {
                    // failure: keep preloader label with message
                    ps.setPreloaderFailed(for: anchor.identifier)
                    print("⚠️ ARSceneManager: video failed for anchor: \(anchor.identifier)")
                }
            }
        }
        
        print("😇 1 ARSceneManager: async loading started for anchor: \(anchor.identifier)")
        
        return parentNode
    }
    
    // This function calls every frame when the camera tracks the target
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let imageAnchor = anchor as? ARImageAnchor else {
                print("⚠️ ∞ ARSceneManager: anchor is not ARImageAnchor")
                return
            }
            
            let id = anchor.identifier
            
            if !imageAnchor.isTracked {
                // Cancel any pending start; schedule a delayed stop
                if let start = self.startWorkItems.removeValue(forKey: id) { start.cancel() }
                
                if self.stopWorkItems[id] == nil {
                    let work = DispatchWorkItem { [weak self] in
                        guard let self else { return }
                        Task { @MainActor in
                            self.videoManager.stopVideo(for: id)
                            self.scannerOverlay.showScanner()
                        }
                        self.stopWorkItems.removeValue(forKey: id)
                    }
                    self.stopWorkItems[id] = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
                }
                
            } else {
                // Cancel any pending stop; schedule a delayed start
                if let stop = self.stopWorkItems.removeValue(forKey: id) { stop.cancel() }
            
                if self.startWorkItems[id] == nil {
                    let work = DispatchWorkItem { [weak self] in
                        guard let self else { return }
                        Task { @MainActor in
                            self.videoManager.startVideo(for: id)
                            self.scannerOverlay.hideScanner()
                        }
                        self.startWorkItems.removeValue(forKey: id)
                    }
                    self.startWorkItems[id] = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: work)
                }
            }
        }
    }
}
