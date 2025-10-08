//
//  AppConstants.swift
//  HGArt
//
//  Created by Stanislav Grinshpun on 2025-10-08.
//

import CoreGraphics
import CoreMedia

/// Application-wide constants
enum AppConstants {
    
    // MARK: - Video Configuration
    enum Video {
        /// Default video scene size for rendering
        static let defaultSceneSize = CGSize(width: 1280, height: 720)
        
        /// Time before end to trigger seamless loop (in seconds)
        static let loopTriggerTime: Double = 0.05
        
        /// Padding around AR image for video plane
        static let planePadding: CGFloat = 0.01
        
        /// Rendering order for video planes
        static let planeRenderingOrder: Int = 2000
    }
    
    // MARK: - Cache Configuration
    enum Cache {
        /// Cache directory name
        static let directoryName = "ARVideos"
        
        /// Maximum cache size in bytes (500 MB)
        static let maxCacheSize: UInt64 = 500 * 1024 * 1024
    }
    
    // MARK: - AR Configuration
    enum AR {
        /// Maximum number of tracked images
        static let maxTrackedImages = 10
        
        /// Preferred frames per second
        static let preferredFPS = 60
    }
    
    // MARK: - UI Configuration
    enum UI {
        /// Animation duration for UI transitions
        static let animationDuration: Double = 0.3
        
        /// Scanner overlay animation duration
        static let scannerAnimationDuration: Double = 1.0
    }
}
