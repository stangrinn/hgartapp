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

class ARSceneVideoOverlay: NSObject {

    private var players: [String: AVPlayer] = [:]
    
    private var playerObservers: [PlayerObserver] = []
    
    private var avPlayerLoopers: [String: AVPlayerLooper] = [:]
    
    private var avQueueLoopers: [String: AVQueuePlayer] = [:]
    
    private var skVideoNodes: [String: SKVideoNode] = [:]

    private let videoCache: VideoCachingPort

    init(videoCache: VideoCachingPort = VideoCacheService()) {
        self.videoCache = videoCache
    }
    
    // MARK: - Async version with caching (updates existing parentNode)
    func createMainOverlayAsync(for imageAnchor: ARImageAnchor,
                                targets: [ARTarget],
                                parentNode: SCNNode,
                                onProgress: @escaping (Double) -> Void) async -> AVQueuePlayer?
        {
            
            guard let name = imageAnchor.referenceImage.name,
              let target = targets.first(where: { $0.name == name }) else {
            return nil
        }

        print("⬇️ Starting video load for \(target.name)")
        
        // Wait for the video to be cached
        guard let url = try? await videoCache.cachedVideoURL(for: target, onProgress: onProgress) else {
            
            print("⚠️ Could not load or cache video for \(target.name)")
            
            return nil
        }
        
        // Create player with cached URL
        let player = createOrGetQueuePlayer(url: url, target: target)
        
        // Find the plane node in parentNode (it should be the first child)
        guard let planeNode = parentNode.childNodes.first, let plane = planeNode.geometry as? SCNPlane else {
            
            print("⚠️ Could not find plane node in parentNode")
            
            return nil
        }
        
        // Create video node and replace placeholder
        await MainActor.run {
            let videoNode = SKVideoNode(avPlayer: player)
            
            videoNode.yScale = -1
            
            let sceneSize = CGSize(width: 1280, height: 720)
            
            let spriteScene = SKScene(size: sceneSize)
            
            spriteScene.backgroundColor = .clear
            
            spriteScene.scaleMode = .aspectFit
            
            videoNode.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
            
            videoNode.size = sceneSize
            
            spriteScene.addChild(videoNode)
            
            plane.firstMaterial?.diffuse.contents = spriteScene
            
            // Reset material transform applied for the preloader
            plane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Identity
            
            skVideoNodes[target.name] = videoNode
            
            // Start playback
            if player.timeControlStatus != .playing {
                player.play()
            }
            
            videoNode.play()
            
            print("🎬 Video loaded and playing for \(target.name) (cached: \(url.isFileURL))")
        }
        
        return player
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
}
