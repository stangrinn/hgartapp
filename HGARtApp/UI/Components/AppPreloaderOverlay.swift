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
    
    // MARK: - App Clip Detection // make some external fuction for all members of application
    var isRunningInAppClip: Bool {
        if Bundle.main.object(forInfoDictionaryKey: "NSAppClip") != nil {
            return true
        }
        if let bundleId = Bundle.main.bundleIdentifier,
           bundleId.contains("Clip") {
            return true
        }
        return false
    }
    
    // MARK: - Preloader Overlay
    init(view: UIView) {
        
        var forResource: String, bgColor: CGColor
        
        if isRunningInAppClip {
            print("🎬 Running in App Clip - using KIDS preloader")
            forResource = "Loader-kids"
            bgColor = UIColor(red: 254 / 255, green: 250 / 255, blue: 235 / 255, alpha: 1.0).cgColor
        } else {
            print("🎬 Running in main app - using full preloader")
            forResource = "Loader"
            bgColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0).cgColor
        }
        
        guard let path = Bundle.main.path(forResource: forResource, ofType: "mp4") else {
            print("Intro video not found")
            return
        }
        
        let player = AVPlayer(url: URL(fileURLWithPath: path))

        let playerLayer = AVPlayerLayer(player: player)
        
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspect
        playerLayer.zPosition = 999
        playerLayer.backgroundColor = bgColor
        playerLayer.frame = view.bounds.insetBy(dx: -1, dy: -1)
        
        view.layer.backgroundColor = bgColor
        view.backgroundColor = UIColor(cgColor: bgColor)
        view.layer.addSublayer(playerLayer)
        
        player.play()
        
        removePreloaderOverlay(whenEndOf: player, remove: playerLayer)
    }
    
    
    
    private func removePreloaderOverlay(whenEndOf player: AVPlayer, remove playerLayer: AVPlayerLayer) {
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
