//
//  VideoOverlayFactoryProtocol.swift
//  HGArt
//
//  Created by Stanislav Grinshpun on 2025-10-08.
//

import ARKit
import AVFoundation
import SceneKit

/// Protocol for creating AR video overlay nodes
/// Handles SceneKit geometry and SpriteKit video rendering
protocol VideoOverlayFactoryProtocol {
    
    /// Create complete overlay node for AR anchor
    /// - Parameters:
    ///   - anchor: AR image anchor for sizing
    ///   - player: Video player to render
    /// - Returns: SCNNode ready to attach to scene
    func createOverlayNode(for anchor: ARImageAnchor, player: AVQueuePlayer) -> SCNNode
    
    /// Create plane geometry for video rendering
    /// - Parameter anchor: AR image anchor for sizing
    /// - Returns: Configured SCNPlane
    func createPlane(for anchor: ARImageAnchor) -> SCNPlane
}
