import UIKit
import AVFoundation
import SceneKit
import ARKit

class ARVideoManager {
    
    private var playersByAnchor: [UUID: AVPlayer] = [:]
    
    private var currentAnchorID: UUID?
    
    private var isPlaying: Bool {
        
        guard let currentAnchorID = currentAnchorID, let player = playersByAnchor[currentAnchorID] else { return false }
        
        return player.timeControlStatus == .playing
    }
    
    private var isMuted: Bool? = nil
    
    private weak var view: UIView?
    
    ///
    init(view: UIView) {
        self.view = view
        setupControls()
    }
    
    func setupControls() {
        ARVideoControls.setupControls(
            view: self.view!,
            target: self,
            muteSelector: #selector(toggleMute),
            isMuted: { [weak self] in self?.isMuted ?? false },
            isPlaying: { [weak self] in self?.isPlaying ?? false }
        )
    }
    
    // This funcion calls everytime when a camera see the target
    func createOrPlayMainOverlay(for anchor: ARImageAnchor, targets: [ARTarget]) -> SCNNode? {
        
        if let player = playersByAnchor[anchor.identifier] {
            
            if !isPlaying { /// This part starts the video from the beginning
                
                // player.seek(to: .zero)
                
                player.play()
                
                print("💣Video !isPlaying")
            }
            
            currentAnchorID = anchor.identifier
            
            ARVideoControls.setControlsVisible(true)
            
            return nil
        }

        if let result = ARVideoOverlay.createMainOverlay(for: anchor, targets: targets) {
            
            currentAnchorID = anchor.identifier
            
            playersByAnchor[anchor.identifier] = result.player
            
            result.player.seek(to: .zero)
            
            result.player.isMuted = (isMuted == nil ? true : isMuted!)  /// Set muted due to the best practicies
            ///
            // Set up seamless looping with immediate seek
            setupSeamlessLoop(for: result.player)
            
            ARVideoControls.updateMuteIcon(isMuted: result.player.isMuted)
            
            ARVideoControls.setControlsVisible(true)
            
            print("💣Video Playing")
            
            return result.node
        }
        
        ARVideoControls.setControlsVisible(false)

        return nil
    }

    func setToStartAndPauseVideo(for anchorID: UUID) {
        
        if let player: AVPlayer = playersByAnchor[anchorID] {
            player.pause()
            player.seek(to: .zero)
        }
        
        ARVideoControls.setControlsVisible(false)
        
        clearCurrentAnchor()
    
    }
    
    @objc func togglePlayPause() {
        guard let currentAnchorID = currentAnchorID,
              let player = playersByAnchor[currentAnchorID] else { return }
        
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
        
    }
    
    @objc func toggleMute() {
        guard let currentAnchorID = currentAnchorID, let player = playersByAnchor[currentAnchorID] else { return }
        
        player.isMuted = !player.isMuted
        
        isMuted = player.isMuted
        
        ARVideoControls.updateMuteIcon(isMuted: player.isMuted)
    }
    
    func clearCurrentAnchor() {
        currentAnchorID = nil
        ARVideoControls.setControlsVisible(false)
    }
    
    private func setupSeamlessLoop(for player: AVPlayer) {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak player] _ in
            // Seek to beginning immediately for seamless loop
            player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
            player?.play()
        }
    }
}
