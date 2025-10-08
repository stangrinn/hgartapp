//
//  VideoPlaybackState.swift
//  HGArt
//
//  Created by Stanislav Grinshpun on 2025-10-08.
//

import Foundation

/// Represents the current state of video playback
enum VideoPlaybackState {
    case idle
    case loading
    case ready
    case playing
    case paused
    case failed(Error)
    
    var isPlaying: Bool {
        if case .playing = self {
            return true
        }
        return false
    }
    
    var isReady: Bool {
        switch self {
        case .ready, .playing, .paused:
            return true
        default:
            return false
        }
    }
}

/// Cache status for video files
enum VideoCacheStatus {
    case notCached
    case downloading(Progress)
    case cached(URL)
    case failed(Error)
    
    var url: URL? {
        if case .cached(let url) = self {
            return url
        }
        return nil
    }
    
    var isCached: Bool {
        if case .cached = self {
            return true
        }
        return false
    }
}
