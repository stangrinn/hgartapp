import Foundation
import UIKit
import ARKit
import SceneKit
import SpriteKit
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate {
    
    let CONFIG_URL: String = "https://helenagrinshpun.art/assets/config.json"

    struct ARTarget: Decodable {
        let name: String
        let imageUrl: String
        let videoUrl: String
        let physicalWidth: Float
    }

    var targets: [ARTarget] = []
    var referenceImages: Set<ARReferenceImage> = []
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
        loadTargetsAndStartSession()
    }

    func loadTargetsAndStartSession() {
        
        guard let configURL = URL(string: CONFIG_URL) else {
            fatalError("Invalid config URL")
        }
        
        URLSession.shared.dataTask(with: configURL) { data, response, error in
            guard let data = data else {
                print("Failed to fetch config: \(error?.localizedDescription ?? "unknown error")")
                return
            }

            do {
                let decoded = try JSONDecoder().decode([String: [ARTarget]].self, from: data)
                
                self.targets = decoded["targets"] ?? []

                let group = DispatchGroup()

                for target in self.targets {

                    guard let imageUrl = URL(string: target.imageUrl) else { continue }

                    group.enter()

                    URLSession.shared.dataTask(with: imageUrl) { imageData, _, _ in defer { group.leave() }
                        
                        guard let imageData = imageData,
                              let uiImage = UIImage(data: imageData),
                              let cgImage = uiImage.cgImage else { return }
                        
                        let arImage = ARReferenceImage(cgImage, orientation: .up, physicalWidth: CGFloat(target.physicalWidth))
                        arImage.name = target.name
                        self.referenceImages.insert(arImage)
                        
                    }.resume()
                }

                group.notify(queue: .main) {
                    let configuration = ARImageTrackingConfiguration()
                    
                    configuration.trackingImages = self.referenceImages
                    
                    configuration.maximumNumberOfTrackedImages = self.referenceImages.count
                    
                    self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                }

            } catch {
                print("Failed to decode config: \(error.localizedDescription)")
            }
        }.resume()
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

        guard let name = imageAnchor.referenceImage.name,
              let target = targets.first(where: { $0.name == name }),
              let url = URL(string: target.videoUrl) else {
            return nil
        }
        
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
