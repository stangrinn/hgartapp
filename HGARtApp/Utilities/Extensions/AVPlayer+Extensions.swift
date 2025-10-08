//
//  AVPlayer+Extensions.swift
//  HGArt
//
//  Created by Stanislav Grinshpun on 2025-10-08.
//

import AVFoundation

extension AVPlayer {
    
    /// Check if player is currently playing
    var isPlaying: Bool {
        return timeControlStatus == .playing
    }
    
    /// Restart playback from beginning
    func restart() {
        seek(to: .zero)
        play()
    }
    
    /// Stop playback and reset to beginning
    func stop() {
        pause()
        seek(to: .zero)
    }
}

extension AVPlayerItem {
    
    /// Check if item is ready to play
    var isReadyToPlay: Bool {
        return status == .readyToPlay
    }
    
    /// Get duration in seconds
    var durationInSeconds: Double? {
        guard duration.isNumeric else { return nil }
        return CMTimeGetSeconds(duration)
    }
}
