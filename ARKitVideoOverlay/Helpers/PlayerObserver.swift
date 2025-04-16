//
//  PlayerObserver.swift
//  ARKitVideoOverlay
//
//  Created by Stanislav Grinshpun on 2025-04-15.
//

import Foundation
import AVFoundation

class PlayerObserver: NSObject {
    private let player: AVPlayer

    init(player: AVPlayer) {
        self.player = player
        super.init()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "status",
              let item = object as? AVPlayerItem else { return }

        if item.status == .readyToPlay {
            print("🎬 Player item is ready. Starting playback.", object as Any)
            DispatchQueue.main.async {
                self.player.play()
            }
        } else if item.status == .failed {
            print("❌ AVPlayerItem failed:", item.error?.localizedDescription ?? "Unknown error")
        }
    }
}
