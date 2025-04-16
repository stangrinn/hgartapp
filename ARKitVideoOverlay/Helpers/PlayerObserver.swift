//
//  PlayerObserver.swift
//  ARKitVideoOverlay
//
//  Created by Stanislav Grinshpun on 2025-04-15.
//

import Foundation
import AVFoundation

class PlayerObserver: NSObject {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "status",
              let item = object as? AVPlayerItem else { return }

        if item.status == .readyToPlay {
            print("🎬 Player item is ready. Starting playback.")
            DispatchQueue.main.async {
                // Здесь вы должны как-то найти соответствующий AVPlayer и вызвать .play()
                // Например, если вы передадите его через init или замыкание
            }
        } else if item.status == .failed {
            print("❌ AVPlayerItem failed:", item.error?.localizedDescription ?? "Unknown error")
        }
    }
}
