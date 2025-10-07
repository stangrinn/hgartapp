import UIKit
import AVFoundation
import SceneKit
import ARKit

class ARVideoManager {
    
    private var playersByAnchor: [UUID: AVQueuePlayer] = [:]
    
    private var currentAnchorID: UUID?
    
    private var isPlaying: Bool {
        
        guard let currentAnchorID = currentAnchorID, let player = playersByAnchor[currentAnchorID] else { return false }
        
        return player.timeControlStatus == .playing
    }
    
    private var isMuted: Bool? = nil
    
    private weak var view: UIView?
    
    
    init(view: UIView) {
        self.view = view
        
        setupControls()
    }
    
    // This funcion calls everytime when a camera see the target
    func createOverlayVideoPlane(for anchor: ARImageAnchor, targets: [ARTarget]) -> SCNNode? {
        
        if let player = playersByAnchor[anchor.identifier] {
            
            startVideo(for: anchor.identifier)
            
            return nil
        }

        if let mainOverlay = ARVideoOverlay.createMainOverlay(for: anchor, targets: targets) {
            
            currentAnchorID = anchor.identifier
            
            playersByAnchor[anchor.identifier] = mainOverlay.player
            
            mainOverlay.player.isMuted = (isMuted == nil ? true : isMuted!)  /// Set muted due to the best practicies
            
            ARVideoControls.updateMuteIcon(isMuted: mainOverlay.player.isMuted)
            
            ARVideoControls.setControlsVisible(true)
            
            print("💣 Video is playing")
            
            return mainOverlay.node
        }
        
        ARVideoControls.setControlsVisible(false)

        return nil
    }

    func stopVideo(for anchorID: UUID) {
        
        if let player: AVPlayer = playersByAnchor[anchorID] {
            
            player.pause()
            
            player.seek(to: .zero)
            
            print("👋 Video is not Playing")
        }
        
        ARVideoControls.setControlsVisible(false)
        
        clearCurrentAnchor()
        
    
    }
    
    func startVideo(for anchorID: UUID) {
        
        guard let player = playersByAnchor[anchorID] else { return }
        
        if isPlaying { return }
        
        print("✅ StartVideo is player playing: \(isPlaying)")
        
//        player.seek(to: .zero)
        
        player.play()
        
        currentAnchorID = anchorID
        
        ARVideoControls.setControlsVisible(true)
        
    }
    
    private func clearCurrentAnchor() {
        currentAnchorID = nil
        ARVideoControls.setControlsVisible(false)
    }
    
    private func setupControls() {
        ARVideoControls.setupControls(
            view: self.view!,
            target: self,
            muteSelector: #selector(toggleMute),
            isMuted: { [weak self] in self?.isMuted ?? false },
            isPlaying: { [weak self] in self?.isPlaying ?? false }
        )
    }
    
    @objc private func togglePlayPause() {
        guard let currentAnchorID = currentAnchorID,
              let player = playersByAnchor[currentAnchorID] else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        
    }
    
    @objc private func toggleMute() {
        guard let currentAnchorID = currentAnchorID, let player = playersByAnchor[currentAnchorID] else { return }
        
        player.isMuted = !player.isMuted
        
        isMuted = player.isMuted
        
        ARVideoControls.updateMuteIcon(isMuted: player.isMuted)
    }

}
