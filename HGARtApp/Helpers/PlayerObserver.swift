//
//  PlayerObserver.swift
//  HGARt
//
//  Created by Stanislav Grinshpun on 2025-04-15.
//

import Foundation
import AVFoundation

class PlayerObserver: NSObject {
    private let _player: AVPlayer
    private var isObserving = false
    
    var player: AVPlayer {
        return _player
    }

    init(player: AVPlayer) {
        self._player = player
        super.init()
    }
    
    func startObserving() {
        guard !isObserving, let currentItem = _player.currentItem else { return }
        currentItem.addObserver(self, forKeyPath: "status", options: [.new, .initial], context: nil)
        isObserving = true
    }
    
    func stopObserving() {
        guard isObserving, let currentItem = _player.currentItem else { return }
        currentItem.removeObserver(self, forKeyPath: "status")
        isObserving = false
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == "status",
              let item = object as? AVPlayerItem else { return }

        if item.status == .readyToPlay {
            print("🎬 Player item is ready. Starting playback.")
            self._player.play()
        } else if item.status == .failed {
            print("❌ AVPlayerItem failed:", item.error?.localizedDescription ?? "Unknown error")
        }
    }
}
