//
//  VideoOverlayManager.swift
//  ARKitVideoOverlay
//
//  Created by Stanislav Grinshpun on 2025-04-06.
//

import SpriteKit
import AVFoundation
import SceneKit
import ARKit
import Foundation
import CoreMedia

class ARVideoOverlayManager {

    private static var playPauseButton: UIButton?
    private static var muteButton: UIButton?
    private static var players: [String: AVPlayer] = [:]
    private static var observers: [PlayerObserver] = []

    static func createPreloaderOverlay(view: UIView) {
        guard let path: String = Bundle.main.path(forResource: "Loader", ofType: "mp4") else {
            print("Intro video not found")
            return
        }

        let player: AVPlayer = AVPlayer(url: URL(fileURLWithPath: path))
        let playerLayer: AVPlayerLayer = AVPlayerLayer(player: player)

        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspect
        playerLayer.zPosition = 999
        playerLayer.backgroundColor = UIColor.black.cgColor

        view.layer.addSublayer(playerLayer)

        player.play()

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                playerLayer.removeFromSuperlayer()
            }
        }
    }

    static func createMainOverlay(for imageAnchor: ARImageAnchor, targets: [ARTarget]) -> (node: SCNNode, player: AVPlayer)? {

        guard let name = imageAnchor.referenceImage.name,
              let target = targets.first(where: { $0.name == name }),
              let url = URL(string: target.videoUrl) else {
            return nil
        }

        let plane = createPlane(width: imageAnchor.referenceImage.physicalSize.width,
                             height: imageAnchor.referenceImage.physicalSize.height)
        
        let player = createOrGetPlayer(url: url, target: target)

        plane.firstMaterial?.diffuse.contents = player

        player.play()

        if player.currentItem?.status == .readyToPlay {
            print("⚠️ Player not ready: \(player.currentItem?.status.rawValue ?? -1)")
        }

        let planeNode: SCNNode = SCNNode(geometry: plane)
        // Draw after other geometry to reduce z-fighting/edge artifacts
        planeNode.renderingOrder = 2000
        planeNode.eulerAngles.x = -.pi / 2

        let parentNode: SCNNode = SCNNode()

        parentNode.addChildNode(planeNode)

        return (parentNode, player)
    }
    
    private static func createOrGetPlayer(url: URL, target: ARTarget) -> AVPlayer {
        let player: AVPlayer

        if let existing = players[target.name] {

            player = existing

            print("♻️ Reusing AVPlayer for \(target.name)")
        } else {

            player = AVPlayer(url: url)

            players[target.name] = player

            print("🎥 Creating new AVPlayer for \(target.name)")

            let observer: PlayerObserver = PlayerObserver(player: player)

            observers.append(observer)

            if let currentItem: AVPlayerItem = player.currentItem {
                currentItem.addObserver(observer, forKeyPath: "status", options: [.new, .initial], context: nil)
            }
        }
        
        return player
    }
    
    private static func createPlane(width: CGFloat, height: CGFloat) -> SCNPlane {
        let plane = SCNPlane(width: width, height: height)
        
        plane.firstMaterial?.diffuse.contents = UIColor.clear
        plane.firstMaterial?.isDoubleSided = false
        plane.firstMaterial?.transparency = 1.0
        plane.firstMaterial?.writesToDepthBuffer = false
        // Prefer constant lighting and clamp sampling to reduce edge shimmer
        plane.firstMaterial?.lightingModel = .constant
        
        plane.firstMaterial?.readsFromDepthBuffer = false
        plane.firstMaterial?.diffuse.wrapS = .clamp
        plane.firstMaterial?.diffuse.wrapT = .clamp
        plane.firstMaterial?.diffuse.mipFilter = .linear
        plane.firstMaterial?.diffuse.minificationFilter = .linear
        plane.firstMaterial?.diffuse.magnificationFilter = .linear
        
        return plane
    }

    static func setupControls(view: UIView,
                              target: Any,
                              muteSelector: Selector,
                              isMuted: @escaping () -> Bool,
                              isPlaying: @escaping () -> Bool) {

        let muteButton = ToggledIconButton(
            defaultIconName: "speaker.wave.2.fill",
            toggledIconName: "speaker.slash.fill",
            backgroundColor: UIColor.black.withAlphaComponent(0.4),
            symbolSize: 14
        )

        muteButton.attach(to: view, target: target, action: muteSelector, toggled: isMuted(), xOffset: 32, yOffset: 32, alignRight: true)
        muteButton.isHidden = true

        self.muteButton = muteButton
    }

    static func setControlsVisible(_ visible: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, animations: {
                muteButton?.alpha = visible ? 1.0 : 0.0
            }, completion: { _ in
                muteButton?.isHidden = !visible
            })
        }
    }

    static func updatePlayPauseIcon(isPlaying: Bool) {
        let iconName: String = isPlaying ? "pause.fill" : "play.fill"

        DispatchQueue.main.async {
            if var config = playPauseButton?.configuration {
                config.image = UIImage(systemName: iconName)
                config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
                playPauseButton?.configuration = config
            }
        }
    }

    static func updateMuteIcon(isMuted: Bool) {
        let icon: String = isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"

        DispatchQueue.main.async {
            if var config = muteButton?.configuration {
                config.image = UIImage(systemName: icon)
                config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
                muteButton?.configuration = config
            }
        }
    }
}
