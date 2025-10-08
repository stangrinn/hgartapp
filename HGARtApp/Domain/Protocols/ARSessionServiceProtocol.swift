//
//  ARSessionServiceProtocol.swift
//  HGArt
//
//  Created by Stanislav Grinshpun on 2025-10-08.
//

import ARKit
import Foundation

/// Protocol for AR session management
/// Handles loading targets and starting AR tracking
protocol ARSessionServiceProtocol {
    
    /// Load AR targets from configuration and start session
    /// - Parameter completion: Called with loaded targets
    func loadTargetsAndStartSession(completion: @escaping ([ARTarget]) -> Void)
    
    /// Pause AR session
    func pauseSession()
    
    /// Resume AR session with current configuration
    func resumeSession()
    
    /// Reset AR session with new targets
    /// - Parameter targets: New target configuration
    func resetSession(with targets: [ARTarget])
}
