import ARKit
import SceneKit

class ARSceneManager: NSObject, ARSCNViewDelegate {
    private var trackedNodes: [UUID: SCNNode] = [:]
    private weak var videoManager: VideoManager?
    private var targets: [ARTarget] = []
    
    init(videoManager: VideoManager) {
        self.videoManager = videoManager
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
            videoManager?.pauseVideo(for: anchor.identifier)
            videoManager?.clearCurrentAnchor()
        } else {
            _ = videoManager?.createOrPlayMainOverlay(for: imageAnchor, targets: targets)
        }
    }
} 
