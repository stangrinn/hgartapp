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
        guard let url = try? await cachedURL(for: target, onProgress: onProgress) else {
            print("⚠️ Could not load or cache video for \(target.name)")
            return nil
        }
        
        // Create player with cached URL
        let player = createOrGetQueuePlayer(url: url, target: target)
        
        // Find the plane node in parentNode (it should be the first child)
        guard let planeNode = parentNode.childNodes.first,
              let plane = planeNode.geometry as? SCNPlane else {
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
    
    // MARK: - Local Video Cache (async/await version)
    func cachedURL(for target: ARTarget, onProgress: @escaping (Double) -> Void) async throws -> URL {
        
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
            onProgress(1.0)
            return fileURL
        }

        // Create folder if needed
        if !fileManager.fileExists(atPath: folderURL.path) {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }

        // Download and cache video (async)
        print("⬇️ Downloading video for \(target.name)...")
        
        onProgress(0.0)

        struct DownloadError: Error { let underlying: Error }

        // 1) Attempt with delegate to stream progress and move to cache inside delegate
        do {
            let finalURL: URL = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
                final class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
                    let onProgress: (Double) -> Void
                    let destination: URL
                    let completion: (Result<URL, Error>) -> Void
                    init(onProgress: @escaping (Double) -> Void, destination: URL, completion: @escaping (Result<URL, Error>) -> Void) {
                        self.onProgress = onProgress
                        self.destination = destination
                        self.completion = completion
                    }
                    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
                        guard totalBytesExpectedToWrite > 0 else { return }
                        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                        DispatchQueue.main.async { self.onProgress(progress) }
                    }
                    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                                    didFinishDownloadingTo location: URL) {
                        do {
                            let fm = FileManager.default
                            let dir = destination.deletingLastPathComponent()
                            if !fm.fileExists(atPath: dir.path) {
                                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                            }
                            if fm.fileExists(atPath: destination.path) {
                                try fm.removeItem(at: destination)
                            }
                            try fm.moveItem(at: location, to: destination)
                            DispatchQueue.main.async { self.onProgress(1.0) }
                            completion(.success(destination))
                        } catch {
                            completion(.failure(error))
                        }
                    }
                    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
                        if let error { completion(.failure(error)) }
                    }
                }

                let cfg = URLSessionConfiguration.default
                cfg.waitsForConnectivity = true
                cfg.allowsExpensiveNetworkAccess = true
                cfg.allowsConstrainedNetworkAccess = true
                let delegate = DownloadDelegate(onProgress: onProgress, destination: fileURL) { result in
                    switch result {
                    case .success(let url): cont.resume(returning: url)
                    case .failure(let err): cont.resume(throwing: DownloadError(underlying: err))
                    }
                }
                let session = URLSession(configuration: cfg, delegate: delegate, delegateQueue: nil)
                let task = session.downloadTask(with: remoteURL)
                task.resume()
            }

            print("✅ Cached video for \(target.name)")
            return finalURL
        } catch {
            // 2) Fallback to simple download (may use different transport)
            print("↩️ Progress download failed, falling back. Error: \(error.localizedDescription)")
            do {
                let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)
                if !fileManager.fileExists(atPath: folderURL.path) {
                    try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
                }
                try fileManager.moveItem(at: tempURL, to: fileURL)
                onProgress(1.0)
                print("✅ Cached video for \(target.name) via fallback")
                return fileURL
            } catch {
                print("❌ Fallback download failed: \(error.localizedDescription)")
                throw error
            }
        }
        
        // All paths above return; no further action needed here.
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
        plane.firstMaterial?.diffuse.contents = UIColor.white
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
