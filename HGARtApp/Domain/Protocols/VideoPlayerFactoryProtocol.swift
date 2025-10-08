//
//  VideoPlayerFactoryProtocol.swift
//  HGArt
//
//  Created by Stanislav Grinshpun on 2025-10-08.
//

import AVFoundation

/// Protocol for creating video players and loopers
/// Factory pattern for AVPlayer components
protocol VideoPlayerFactoryProtocol {
    
    /// Create AVQueuePlayer for video playback
    /// - Parameter url: Local or remote video URL
    /// - Returns: Configured AVQueuePlayer instance
    func createPlayer(for url: URL) -> AVQueuePlayer
    
    /// Create AVPlayerLooper for seamless video looping
    /// - Parameters:
    ///   - player: Queue player to loop
    ///   - item: Player item to use as template
    /// - Returns: AVPlayerLooper that manages looping
    func createLooper(player: AVQueuePlayer, item: AVPlayerItem) -> AVPlayerLooper
    
    /// Create complete player with looper configured
    /// - Parameter url: Video URL
    /// - Returns: Tuple of player and looper
    func createLoopingPlayer(for url: URL) -> (player: AVQueuePlayer, looper: AVPlayerLooper)
}
