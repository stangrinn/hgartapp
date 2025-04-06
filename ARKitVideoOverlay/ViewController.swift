import UIKit
import ARKit
import SceneKit
import SpriteKit
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate {

    var player: AVPlayer?
    var sceneView: ARSCNView!

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView = ARSCNView(frame: view.frame)
        view.addSubview(sceneView)

        sceneView.delegate = self
        sceneView.scene = SCNScene()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing AR Resources")
        }

        let configuration = ARImageTrackingConfiguration()
        configuration.trackingImages = referenceImages
        configuration.maximumNumberOfTrackedImages = 1

        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let imageAnchor = anchor as? ARImageAnchor else { return nil }

        let referenceImage = imageAnchor.referenceImage
        let width = referenceImage.physicalSize.width
        let height = referenceImage.physicalSize.height

        let plane = SCNPlane(width: width, height: height)

        #if APPCLIP
        guard let url = URL(string: "https://helenagrinshpun.art/assets/videos/Magician.mp4") else { return nil }
        #else
        guard let url = Bundle.main.url(forResource: "Magic", withExtension: "mp4") else { return nil }
        #endif
        
        let player = AVPlayer(url: url)
        self.player = player
        player.actionAtItemEnd = .none
        let videoNode = SKVideoNode(avPlayer: player)
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            player.seek(to: .zero)
            player.play()
        }
        
        videoNode.play()

        let videoScene = SKScene(size: CGSize(width: 1280, height: 720))
        videoNode.position = CGPoint(x: videoScene.size.width / 2, y: videoScene.size.height / 2)
        videoNode.size = videoScene.size
        videoNode.yScale = -1 // Invert by Y
        videoScene.addChild(videoNode)

        plane.firstMaterial?.diffuse.contents = videoScene
        plane.firstMaterial?.isDoubleSided = true

        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2

        let parentNode = SCNNode()
        parentNode.addChildNode(planeNode)
        

        return parentNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }

        if imageAnchor.isTracked {
            player?.play()
        } else {
            player?.pause()
        }
    }
}
