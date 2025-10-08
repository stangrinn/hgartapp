//
//  AppPreloaderOverlay.swift
//  HGArt
//
//  Created by Web TL AE Stanislav Grinshpun on 2025-10-07.
//

import ARKit
import AVFoundation
import CoreMedia
import Foundation
import SceneKit
import SpriteKit

class AppPreloaderOverlay {
    
    // MARK: - Preloader Overlay
    static func run(view: UIView) {
        
        let (path, matchedBgColor) = getResourcesByInstance()
        
        if(path.isEmpty) { return }
        
        let player = AVPlayer(url: URL(fileURLWithPath: path))

        let playerLayer = AVPlayerLayer(player: player)
        
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspect
        playerLayer.zPosition = 999
        playerLayer.backgroundColor = matchedBgColor
        playerLayer.frame = view.bounds.insetBy(dx: -1, dy: -1)
        
        view.layer.backgroundColor = matchedBgColor
        view.backgroundColor = UIColor(cgColor: matchedBgColor)
        view.layer.addSublayer(playerLayer)
        
        player.play()
        
        removePreloaderOverlay(whenEndOf: player, remove: playerLayer)
    }
    
    static private func getResourcesByInstance() -> (String, CGColor) {
        
        var forResource: String
        var bgColor: CGColor
        var videoColor: [CGFloat]
                
        // Local fallback for App Clip detection: prefer Bundle extension when available
        let runningInAppClip: Bool = {
            if Bundle.main.object(forInfoDictionaryKey: "NSAppClip") != nil { return true }
            if let bundleId = Bundle.main.bundleIdentifier { return bundleId.contains("Clip") }
            return false
        }()

        if runningInAppClip {
            
            print("🎬 Running in App Clip - using KIDS preloader")
            
            forResource = "Loader-kids"
            
            bgColor = UIColor(red: 254/255, green: 250/255, blue: 235/255, alpha: 1.0).cgColor
        
            videoColor = [254.0/255.0, 250.0/255.0, 235.0/255.0, 1.0]
            
        } else {
            print("🎬 Running in main app - using full preloader")
            
            forResource = "Loader"
            
            bgColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0).cgColor
            
            videoColor = [0.0/255.0, 0.0/255.0, 0.0/255.0, 1.0]
        }
        
        // Get the full path to the video file
        guard let path = Bundle.main.path(forResource: forResource, ofType: "mp4") else {
            
            print("❌ Video file '\(forResource).mp4' not found in bundle")
            
            return ("", bgColor)
        }
        
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpace.init(name: CGColorSpace.displayP3)!
        
        let components: [CGFloat] = videoColor
        
        let matchedBgColor = CGColor(colorSpace: colorSpace, components: components) ?? bgColor
                
        return (path, matchedBgColor)
    }
    
    static private func removePreloaderOverlay(whenEndOf player: AVPlayer, remove playerLayer: AVPlayerLayer) {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                playerLayer.removeFromSuperlayer()
            }
        }
    }
}
