import UIKit
import AVFoundation
import SceneKit
import ARKit

class VideoManager {
    private var playersByAnchor: [UUID: AVPlayer] = [:]
    private var currentAnchorID: UUID?
    private var isPlaying = true
    private var isMuted = false
    private weak var view: UIView?
    
    init(view: UIView) {
        self.view = view
    }
    
    func setupControls(
        view: UIView,
        target: Any,
        playPauseSelector: Selector,
        recordSelector: Selector,
        muteSelector: Selector
    ) {
        VideoOverlayManager.setupControls(
            view: view,
            target: target,
            playPauseSelector: playPauseSelector,
            recordSelector: recordSelector,
            muteSelector: muteSelector,
            isMuted: { [weak self] in self?.isMuted ?? false },
            isPlaying: { [weak self] in self?.isPlaying ?? false }
        )
    }
    
    func createOrPlayMainOverlay(for anchor: ARImageAnchor, targets: [ARTarget]) -> SCNNode? {
        if let player = playersByAnchor[anchor.identifier] {
            if player.timeControlStatus != .playing {
                player.seek(to: .zero)
                player.play()
            }
            isPlaying = true
            VideoOverlayManager.updatePlayPauseIcon(isPlaying: isPlaying)
            return nil
        }

        if let result = VideoOverlayManager.createMainOverlay(for: anchor, targets: targets) {
            currentAnchorID = anchor.identifier
            playersByAnchor[anchor.identifier] = result.player
            result.player.seek(to: .zero)
            isPlaying = true
            VideoOverlayManager.updatePlayPauseIcon(isPlaying: isPlaying)
            return result.node
        }
        
        return nil
    }
    
    func togglePlayPause() {
        guard let currentAnchorID = currentAnchorID,
              let player = playersByAnchor[currentAnchorID] else {
            print("Player is nil")
            return
        }
        
        if player.timeControlStatus == .playing {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        
        VideoOverlayManager.updatePlayPauseIcon(isPlaying: isPlaying)
    }
    
    func toggleMute() {
        guard let currentAnchorID = currentAnchorID,
              let player = playersByAnchor[currentAnchorID] else { return }
        
        player.isMuted = !player.isMuted
        isMuted.toggle()
        VideoOverlayManager.updateMuteIcon(isMuted: isMuted)
    }
    
    func pauseVideo(for anchorID: UUID) {
        if let player = playersByAnchor[anchorID] {
            player.pause()
            player.seek(to: .zero)
        }
        isPlaying = false
        VideoOverlayManager.updatePlayPauseIcon(isPlaying: isPlaying)
    }
    
    func clearCurrentAnchor() {
        currentAnchorID = nil
    }
} 
