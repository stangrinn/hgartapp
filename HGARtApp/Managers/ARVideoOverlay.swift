//
//  VideoOverlayManager.swift
//  HGARt
//
//  Created by Stanislav Grinshpun on 2025-04-06.
//

import SpriteKit
import AVFoundation
import SceneKit
import ARKit
import Foundation
import CoreMedia

class ARVideoOverlay {

    private static var playPauseButton: UIButton?
    private static var muteButton: UIButton?
    private static var players: [String: AVPlayer] = [:]
    private static var observers: [PlayerObserver] = []
    private weak var videoManager: ARVideoManager?
    
    /// MARK: - App Clip Detection


    static func createPreloaderOverlay(view: UIView) {
        var forResource: String
        var bgColor: CGColor
        var videoColor: [CGFloat]
        
        // Check if running in App Clip for different behavior
        if isRunningInAppClip {
            print("🎬 Running in App Clip - using KIDS preloader")
            forResource = "Loader-kids"
            bgColor = UIColor(red: 254/255, green: 250/255, blue: 235/255, alpha: 1.0).cgColor
            videoColor = [254.0/255.0, 250.0/255.0, 235.0/255.0, 1.0]
        } else {
            print("🎬 Running in main app - using full preloader")
            forResource = "Loader"
            bgColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0).cgColor
            videoColor = [0.0/255.0, 0.0/255.0, 0.0/255.0, 1.0]
        }
        
        guard let path: String = Bundle.main.path(forResource: forResource, ofType: "mp4") else {
            print("Intro video not found")
            return
        }

        let player: AVPlayer = AVPlayer(url: URL(fileURLWithPath: path))
        
        let playerLayer: AVPlayerLayer = AVPlayerLayer(player: player)

        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspect
        playerLayer.zPosition = 999
        
        // Synchronize color spaces to avoid visual differences
        if #available(iOS 10.0, *) {
            playerLayer.pixelBufferAttributes = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
        }
        
        // Create color with same color space as video
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpace.init(name: CGColorSpace.displayP3)!
        let components: [CGFloat] = videoColor
        let matchedBgColor = CGColor(colorSpace: colorSpace, components: components) ?? bgColor
        
        playerLayer.backgroundColor = matchedBgColor
        playerLayer.frame = view.bounds.insetBy(dx: -1, dy: -1) // Expand by 1 pixel to avoid edge artifacts

        // Additional rendering settings to match colors
        view.layer.backgroundColor = matchedBgColor
        
        view.backgroundColor = UIColor(cgColor: matchedBgColor)
        
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

        let plane = createPlane(imageAnchor: imageAnchor)
            
        let player = createOrGetPlayer(url: url, target: target)

        plane.firstMaterial?.diffuse.contents = player

        player.play()

        if player.currentItem?.status != .readyToPlay {
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
                
                // Add error handling for player items
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemFailedToPlayToEndTime,
                    object: currentItem,
                    queue: .main
                ) { notification in
                    if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                        print("❌ Player failed to play: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        return player
    }
    
    private static func createPlane(imageAnchor: ARImageAnchor) -> SCNPlane {
        
        let padding: CGFloat = 0.01
        let width = imageAnchor.referenceImage.physicalSize.width * (1.0 + padding)
        let height = imageAnchor.referenceImage.physicalSize.height * (1.0 + padding)
        
        let plane = SCNPlane(width: width, height: height)
        // Use an opaque black material so the plane occludes the real-world background
        plane.firstMaterial?.diffuse.contents = UIColor.black
        // Make the plane double-sided so it is visible from both sides of the anchor
        plane.firstMaterial?.isDoubleSided = true
        // Ensure the material is fully opaque
        plane.firstMaterial?.transparency = 1.0
        // Write to depth buffer so the plane properly occludes content behind it
        plane.firstMaterial?.writesToDepthBuffer = true
        // Prefer constant lighting and clamp sampling to reduce edge shimmer
        plane.firstMaterial?.lightingModel = .constant

        // Read from depth buffer to participate in depth testing
        plane.firstMaterial?.readsFromDepthBuffer = true
        plane.firstMaterial?.diffuse.wrapS = .clamp
        plane.firstMaterial?.diffuse.wrapT = .clamp
        plane.firstMaterial?.diffuse.mipFilter = .linear
        plane.firstMaterial?.diffuse.minificationFilter = .linear
        plane.firstMaterial?.diffuse.magnificationFilter = .linear
        
        return plane
    }

    
    // Determines if the app is running as an App Clip
    static var isRunningInAppClip: Bool {
        // Method 1: Check for NSAppClip key in Info.plist (most reliable)
        if Bundle.main.object(forInfoDictionaryKey: "NSAppClip") != nil {
            return true
        }
        
        // Method 2: Check bundle identifier contains "Clip"
        if let bundleId = Bundle.main.bundleIdentifier,
            bundleId.contains("Clip") {
            return true
        }
        
        return false
    }
}
