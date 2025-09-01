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

class VideoOverlayManager {

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

        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width,
                             height: imageAnchor.referenceImage.physicalSize.height)
        
        plane.firstMaterial?.diffuse.contents = UIColor.clear
        plane.firstMaterial?.isDoubleSided = true
        plane.firstMaterial?.transparency = 1.0
        plane.firstMaterial?.writesToDepthBuffer = false

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

        let videoNode: SKVideoNode = SKVideoNode(avPlayer: player)

        player.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none

        print("🎥 Preparing AVPlayer with URL: \(url)")

        Task { @MainActor in
            do {
                let asset = AVURLAsset(url: url)

                let tracks = try await asset.loadTracks(withMediaType: .video)

                guard let track = tracks.first else { return }

                let size = try await track.load(.naturalSize)

                let transform = try await track.load(.preferredTransform)

                let transformedSize = size.applying(transform)

                let width = abs(transformedSize.width)

                let height = abs(transformedSize.height)

                let videoScene = SKScene(size: CGSize(width: width, height: height))

                videoNode.position = CGPoint(x: width / 2, y: height / 2)

                videoNode.size = CGSize(width: width, height: height)

                videoNode.yScale = -1

                videoScene.addChild(videoNode)

                print("✅ Video scene created, assigning to plane")

                plane.firstMaterial?.diffuse.contents = videoScene

                if player.currentItem?.status == .readyToPlay {
                    print("⚠️ Player not ready: \(player.currentItem?.status.rawValue ?? -1)")
                }
            } catch {
                print("Failed to load video size: \(error)")
                print("❌ Error loading asset track info: \(error.localizedDescription)")
            }
        }

        let planeNode: SCNNode = SCNNode(geometry: plane)

        planeNode.eulerAngles.x = -.pi / 2

        let parentNode: SCNNode = SCNNode()

        parentNode.addChildNode(planeNode)

        return (parentNode, player)
    }

    static func setupControls(view: UIView,
                              target: Any,
//                              playPauseSelector: Selector,
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
