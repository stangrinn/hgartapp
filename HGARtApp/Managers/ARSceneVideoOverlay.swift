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

class ARSceneVideoOverlay {

    private var players: [String: AVPlayer] = [:]
    private var playerObservers: [PlayerObserver] = []
    private var avPlayerLoopers: [String: AVPlayerLooper] = [:]
    private var avQueueLoopers: [String: AVQueuePlayer] = [:]
    private var skVideoNodes: [String: SKVideoNode] = [:]
    
    // MARK: - Async version with caching
    func createMainOverlayAsync(for imageAnchor: ARImageAnchor, targets: [ARTarget]) async -> (
        node: SCNNode, player: AVQueuePlayer
    )? {
        guard let name = imageAnchor.referenceImage.name,
              let target = targets.first(where: { $0.name == name }) else {
            return nil
        }

        let plane = createPlane(imageAnchor: imageAnchor)
        
        let parentNode = SCNNode()
        let planeNode = SCNNode(geometry: plane)
        planeNode.renderingOrder = 2000
        planeNode.eulerAngles.x = -.pi / 2
        parentNode.addChildNode(planeNode)
        
        print("Plane BG BEFORE: \(String(describing: plane.firstMaterial?.diffuse.contents))")

        // Wait for the video to be cached
        guard let url = try? await cachedURL(for: target) else {
            print("⚠️ Could not load or cache video for \(target.name)")
            return nil
        }
        
        

        // NOW we have the URL and can create the player
        let player = createOrGetQueuePlayer(url: url, target: target)

        // Create video node and scene on main actor
        await MainActor.run {
            let videoNode = SKVideoNode(avPlayer: player)
            
            videoNode.yScale = -1

            let sceneSize = CGSize(width: 1280, height: 720)
            
            let spriteScene = SKScene(size: sceneSize)
            
            spriteScene.scaleMode = .aspectFit
            
            videoNode.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
            
            videoNode.size = sceneSize
            
            spriteScene.addChild(videoNode)

            plane.firstMaterial?.diffuse.contents = spriteScene
            
            print("Plane BG AFTER: \(String(describing: plane.firstMaterial?.diffuse.contents))")
            
            skVideoNodes[target.name] = videoNode
        }

        // Start playback on main thread
        await MainActor.run {
            if let videoNode = skVideoNodes[target.name] {
                if player.timeControlStatus != .playing {
                    player.play()
                }
                
                videoNode.play()
            
                print("🎬 SKVideoNode started for \(target.name) (cached: \(url.isFileURL))")
            }
        }

        
        return (parentNode, player)
    }
    
    // MARK: - Local Video Cache (async/await version)
    func cachedURL(for target: ARTarget) async throws -> URL {
        
        guard let remoteURL = URL(string: target.videoUrl) else {
            print("❌ Invalid video URL for \(target.name)")
            throw NSError(domain: "ARVideoOverlay", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        let fileManager = FileManager.default
        
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        let folderURL = cacheDir.appendingPathComponent("ARVideos", isDirectory: true)
        
        let fileURL = folderURL.appendingPathComponent(remoteURL.lastPathComponent)

        // If the file already exists, return the local path immediately
        if fileManager.fileExists(atPath: fileURL.path) {
            print("📦 Using cached video for \(target.name)")
            return fileURL
        }

        // Create folder if needed
        if !fileManager.fileExists(atPath: folderURL.path) {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }

        // Download and cache video (async)
        print("⬇️ Downloading video for \(target.name)...")
        
        let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)
        
        try fileManager.moveItem(at: tempURL, to: fileURL)
        
        print("✅ Cached video for \(target.name)")
        
        return fileURL
    }

    // MARK: - Looper Creation
    private func createOrGetQueuePlayer(url: URL, target: ARTarget) -> AVQueuePlayer {
        
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

    private func createPlane(imageAnchor: ARImageAnchor) -> SCNPlane {
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
