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
    init(view: UIView) {
        
        let forResource: String = "Loader-kids"
        
        let bgColor: CGColor = UIColor(red: 254 / 255, green: 250 / 255, blue: 235 / 255, alpha: 1.0).cgColor
        
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                playerLayer.removeFromSuperlayer()
            }
        }
    }
}
