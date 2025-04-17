import UIKit
import AVFoundation
import SceneKit
import ARKit

class VideoManager {
    private var playersByAnchor: [UUID: AVPlayer] = [:]
    private var currentAnchorID: UUID?
    private var isPlaying: Bool {
        guard let currentAnchorID = currentAnchorID,
              let player = playersByAnchor[currentAnchorID] else { return false }
        return player.timeControlStatus == .playing
    }
    private var isMuted: Bool? = nil
    
    private weak var view: UIView?
    
    
    init(view: UIView) {
        self.view = view
    }
    
    func setupControls(view: UIView) {
        VideoOverlayManager.setupControls(
            view: view,
            target: self,
//            playPauseSelector: #selector(togglePlayPause),
            muteSelector: #selector(toggleMute),
            isMuted: { [weak self] in self?.isMuted ?? false },
            isPlaying: { [weak self] in self?.isPlaying ?? false }
        )
    }
    
    func createOrPlayMainOverlay(for anchor: ARImageAnchor, targets: [ARTarget]) -> SCNNode? {
        
        if let player = playersByAnchor[anchor.identifier] {
            
            if !isPlaying { /// This part starts the video from the beginning
                player.seek(to: .zero)
                player.play()
            }
            
            currentAnchorID = anchor.identifier
            
            VideoOverlayManager.setControlsVisible(true)
            
            return nil
        }

        if let result = VideoOverlayManager.createMainOverlay(for: anchor, targets: targets) {
            
            currentAnchorID = anchor.identifier
            
            playersByAnchor[anchor.identifier] = result.player
            
            result.player.seek(to: .zero)
            
            result.player.isMuted = (isMuted == nil ? false : isMuted)!  /// Set muted due to the best practicies
            
            let player = result.player

            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { [weak player] _ in
                player?.seek(to: .zero)
            }
            
            VideoOverlayManager.updateMuteIcon(isMuted: result.player.isMuted)
            
//            VideoOverlayManager.updatePlayPauseIcon(isPlaying: true)
            
            VideoOverlayManager.setControlsVisible(true)
            
            return result.node
        }
        
        VideoOverlayManager.setControlsVisible(false)

        return nil
    }

    func setToStartAndPauseVideo(for anchorID: UUID) {
        
        if let player = playersByAnchor[anchorID] {
            player.pause()
            player.seek(to: .zero)
        }
        
        VideoOverlayManager.setControlsVisible(false)
        
//        VideoOverlayManager.updatePlayPauseIcon(isPlaying: false)
    }
    
    @objc func togglePlayPause() {
        guard let currentAnchorID = currentAnchorID,
              let player = playersByAnchor[currentAnchorID] else { return }
        
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
        
//        VideoOverlayManager.updatePlayPauseIcon(isPlaying: isPlaying)
    }
    
    @objc func toggleMute() {
        guard let currentAnchorID = currentAnchorID,
              let player = playersByAnchor[currentAnchorID] else { return }
        
        
        player.isMuted = !player.isMuted
        
        isMuted = player.isMuted
        
        VideoOverlayManager.updateMuteIcon(isMuted: player.isMuted)
    }
    
    func clearCurrentAnchor() {
        currentAnchorID = nil
        VideoOverlayManager.setControlsVisible(false)
    }
}
