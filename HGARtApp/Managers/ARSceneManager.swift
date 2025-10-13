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
        
        plane.firstMaterial?.diffuse.contents = preloaderScene()
        
        plane.firstMaterial?.isDoubleSided = true
        
        plane.firstMaterial?.lightingModel = .constant
        
        let planeNode = SCNNode(geometry: plane)
        
        planeNode.renderingOrder = 2000
        
        planeNode.eulerAngles.x = -.pi / 2
        
        parentNode.addChildNode(planeNode)
        
        print("📦 Placeholder node created and added immediately")
        
        // Load video asynchronously and update the plane
        Task {
            await videoManager.createOverlayVideoPlaneAsync(
                for: imageAnchor,
                targets: targets,
                parentNode: parentNode
            )
            
            await MainActor.run {
                scannerOverlay.hideScanner()
                print("✅ 1 ARSceneManager: async video loaded for anchor: \(anchor.identifier)")
            }
        }
        
        print("😇 1 ARSceneManager: async loading started for anchor: \(anchor.identifier)")
        
        return parentNode
    }
    
    // This function calls every frame when the camera tracks the target
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let imageAnchor = anchor as? ARImageAnchor else {
            print("💩 ∞ ARSceneManager: anchor is not ARImageAnchor")
            
            return
        }
        
        if !imageAnchor.isTracked {
            Task { @MainActor in
                self.videoManager.stopVideo(for: anchor.identifier)
                self.scannerOverlay.showScanner()
            }
        } else {
            Task { @MainActor in
                self.videoManager.startVideo(for: anchor.identifier)
                self.scannerOverlay.hideScanner()
            }
        }
    }

    private func preloaderScene() -> SKScene {
        let sceneSize = CGSize(width: 1280, height: 720)
        let scene = SKScene(size: sceneSize)
        scene.scaleMode = .aspectFit
        scene.backgroundColor = UIColor(white: 255.0, alpha: 0.5)

        guard let image = UIImage(named: "ARVideoPreloader") else {
            print("⚠️ ARVideoPreloader asset not found")
            return scene
        }

        let texture = SKTexture(image: image)
        let sprite = SKSpriteNode(texture: texture)
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        sprite.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)

        let fitsWidth = sceneSize.width / texture.size().width
        let fitsHeight = sceneSize.height / texture.size().height
        let maxScale = min(fitsWidth, fitsHeight) * 0.8
        let appliedScale = min(1.0, maxScale)
        sprite.xScale = appliedScale
        sprite.yScale = -appliedScale

        scene.addChild(sprite)

        return scene
    }
} 
