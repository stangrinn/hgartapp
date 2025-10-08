//
//  VideoPlaybackManagerProtocol.swift
//  HGArt
//
//  Created by Stanislav Grinshpun on 2025-10-08.
//

import ARKit
import AVFoundation
import SceneKit

/// Protocol for managing video playback lifecycle
/// Coordinates caching, player creation, and overlay generation
protocol VideoPlaybackManagerProtocol {
    
    /// Create video overlay with player for AR anchor
    /// - Parameters:
    ///   - anchor: AR image anchor
    ///   - target: AR target configuration
    /// - Returns: Tuple of scene node and player
    /// - Throws: VideoCacheError or playback errors
    func createVideoOverlay(
        for anchor: ARImageAnchor,
        target: ARTarget
    ) async throws -> (node: SCNNode, player: AVQueuePlayer)
    
    /// Get existing player for target if available
    /// - Parameter target: AR target
    /// - Returns: Existing player or nil
    func getPlayer(for target: ARTarget) -> AVQueuePlayer?
    
    /// Clean up all players and resources
    func cleanup()
    
    /// Preload videos for multiple targets
    /// - Parameter targets: Array of targets to preload
    func preloadVideos(for targets: [ARTarget]) async
}
