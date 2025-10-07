//
//  ARVideoOverlay.swift
//  HGARt
//
//  Created by Stanislav Grinshpun on 2025-04-06.
//

import ARKit
import AVFoundation
import CoreMedia
import Foundation
import SceneKit
import SpriteKit

class ARVideoOverlay {

    private static var players: [String: AVPlayer] = [:]
    private static var playerObservers: [PlayerObserver] = []
    private static var avPlayerLoopers: [String: AVPlayerLooper] = [:]
    private static var avQueueLoopers: [String: AVQueuePlayer] = [:]
    private static var skVideoNodes: [String: SKVideoNode] = [:]
    
    // MARK: - Main Overlay with SKVideoNode
    static func createMainOverlay(for imageAnchor: ARImageAnchor, targets: [ARTarget]) -> (
        node: SCNNode, player: AVQueuePlayer
    )? {

        guard let name = imageAnchor.referenceImage.name,
              let target = targets.first(where: { $0.name == name }),
              let url = URL(string: target.videoUrl)
        else {
            return nil
        }

        let plane = createPlane(imageAnchor: imageAnchor)
        
        let player = createOrGetQueuePlayer(url: url, target: target)

        // Create SKVideoNode-based scene for stable rendering
        let videoNode = SKVideoNode(avPlayer: player)
        
        videoNode.yScale = -1 // Flip to match SceneKit coordinates

        let sceneSize = CGSize(width: 1280, height: 720)
        let spriteScene = SKScene(size: sceneSize)
        spriteScene.scaleMode = .aspectFit
        
        videoNode.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        videoNode.size = sceneSize
        
        spriteScene.addChild(videoNode)

        plane.firstMaterial?.diffuse.contents = spriteScene
        
        skVideoNodes[target.name] = videoNode

        let planeNode = SCNNode(geometry: plane)
        planeNode.renderingOrder = 2000
        planeNode.eulerAngles.x = -.pi / 2

        let parentNode = SCNNode()
        parentNode.addChildNode(planeNode)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            
            if player.timeControlStatus != .playing {
                player.play()
            }
            
            videoNode.play()
            
            print("🎬 SKVideoNode started for \(target.name), \(player)")
        }

        return (parentNode, player)
    }
    
    // MARK: - Local Video Cache
    static func cachedURL(for target: ARTarget, completion: @escaping (URL?) -> Void) {
        
        guard let remoteURL = URL(string: target.videoUrl) else {
            
            print("❌ Invalid video URL for \(target.name)")
            
            completion(nil)
            
            return
        }

        let fileManager = FileManager.default
        
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        let folderURL = cacheDir.appendingPathComponent("ARVideos", isDirectory: true)
        
        let fileURL = folderURL.appendingPathComponent(remoteURL.lastPathComponent)

        // If the file already exists, we return the local path
        if fileManager.fileExists(atPath: fileURL.path) {
            
            print("📦 Using cached video for \(target.name)")
            
            completion(fileURL)
            
            return
        }

        // Create folder if demand
        if !fileManager.fileExists(atPath: folderURL.path) {
            try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }

        // Dowload and cache videos
        print("⬇️ Downloading video for \(target.name)...")
        
        let task = URLSession.shared.downloadTask(with: remoteURL) { tempURL, _, error in
        
            if let tempURL = tempURL, error == nil {
                do {
                    try fileManager.moveItem(at: tempURL, to: fileURL)
                    print("✅ Cached video for \(target.name)")
                    DispatchQueue.main.async { completion(fileURL) }
                } catch {
                    print("❌ Failed to move cached file: \(error)")
                    DispatchQueue.main.async { completion(nil) }
                }
            } else {
                print("❌ Failed to download video for \(target.name): \(error?.localizedDescription ?? "unknown error")")
                DispatchQueue.main.async { completion(nil) }
            }
        }
        task.resume()
    }

    // MARK: - Looper Creation
    private static func createOrGetQueuePlayer(url: URL, target: ARTarget) -> AVQueuePlayer {
        
        let player: AVQueuePlayer

        if let existing = avQueueLoopers[target.name] {
            
            player = existing
        
            print("♻️ Reusing AVQueuePlayer for \(target.name)")
            
        } else {
            
            let item = AVPlayerItem(url: url)
            
            player = AVQueuePlayer(playerItem: item)
            
            let looper = AVPlayerLooper(player: player, templateItem: item)

            avQueueLoopers[target.name] = player
            
            avPlayerLoopers[target.name] = looper

            print("🎥 Created AVQueuePlayer + AVPlayerLooper for \(target.name)")
            
            playerObservers.append(PlayerObserver(player: player))
        }

        return player
    }

    // MARK: - Utilities
    private static func createOrGetPlayer(url: URL, target: ARTarget) -> AVPlayer {
        
        let player: AVPlayer
        
        if let existing = players[target.name] {
            
            player = existing
        
            print("♻️ Reusing AVPlayer for \(target.name)")
            
        } else {
            
            player = AVPlayer(url: url)
            
            players[target.name] = player
            
            print("🎥 Creating new AVPlayer for \(target.name)")
            
            playerObservers.append(PlayerObserver(player: player))
        }
        return player
    }

    private static func createPlane(imageAnchor: ARImageAnchor) -> SCNPlane {
        let padding: CGFloat = 0.01
        let width = imageAnchor.referenceImage.physicalSize.width * (1.0 + padding)
        let height = imageAnchor.referenceImage.physicalSize.height * (1.0 + padding)

        let plane = SCNPlane(width: width, height: height)
        plane.firstMaterial?.diffuse.contents = UIColor.black
        plane.firstMaterial?.isDoubleSided = true
        plane.firstMaterial?.transparency = 1.0
        plane.firstMaterial?.writesToDepthBuffer = true
        plane.firstMaterial?.lightingModel = .constant
        plane.firstMaterial?.readsFromDepthBuffer = true
        plane.firstMaterial?.diffuse.wrapS = .clamp
        plane.firstMaterial?.diffuse.wrapT = .clamp
        plane.firstMaterial?.diffuse.mipFilter = .linear
        plane.firstMaterial?.diffuse.minificationFilter = .linear
        plane.firstMaterial?.diffuse.magnificationFilter = .linear
        return plane
    }
}
