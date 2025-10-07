//
//  PlayerObserver.swift
//  HGARt
//
//  Created by Stanislav Grinshpun on 2025-04-15.
//

import AVFoundation
import Foundation

class PlayerObserver: NSObject {
    private let _player: AVPlayer
    private var isObserving = false

    var player: AVPlayer {
        return _player
    }

    init(player: AVPlayer) {
        self._player = player
        super.init()
        observeErrors(for: player)
    }

    func observeErrors(for player: AVPlayer) {
        
        if let currentItem: AVPlayerItem = player.currentItem {
            currentItem.addObserver(self, forKeyPath: "status", options: [.new, .initial], context: nil)

            // Add error handling for player items
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemFailedToPlayToEndTime,
                object: currentItem,
                queue: .main
            ) { notification in
                if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey]
                    as? Error
                {
                    print("❌ Player failed to play: \(error.localizedDescription)")
                }
            }
        }
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
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == "status", let item = object as? AVPlayerItem else { return }

        if item.status == .readyToPlay {
            print("🎬 Player item is ready. Starting playback.")
            self._player.play()
        } else if item.status == .failed {
            print("❌ AVPlayerItem failed:", item.error?.localizedDescription ?? "Unknown error")
        }
    }
}
