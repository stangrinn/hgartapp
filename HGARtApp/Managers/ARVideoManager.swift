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
    
    // This function calls every time when a camera sees the target
    func createOverlayVideoPlane(for anchor: ARImageAnchor, targets: [ARTarget]) -> SCNNode? {
        
        // If player already exists, just start it
        if playersByAnchor[anchor.identifier] != nil {
            startVideo(for: anchor.identifier)
            return nil
        }

        // Try synchronous version first (for remote URLs)
        if let mainOverlay = ARVideoOverlay.createMainOverlay(for: anchor, targets: targets) {
            
            currentAnchorID = anchor.identifier
            playersByAnchor[anchor.identifier] = mainOverlay.player
            mainOverlay.player.isMuted = (isMuted == nil ? true : isMuted!)
            
            ARVideoControls.updateMuteIcon(isMuted: mainOverlay.player.isMuted)
            ARVideoControls.setControlsVisible(true)
            
            print("💣 Video is playing (sync)")
            
            return mainOverlay.node
        }
        
        ARVideoControls.setControlsVisible(false)
        return nil
    }
    
    // Async version with video caching
    func createOverlayVideoPlaneAsync(for anchor: ARImageAnchor, targets: [ARTarget], parentNode: SCNNode) async {
        
        // If player already exists, just start it
        if playersByAnchor[anchor.identifier] != nil {
            await MainActor.run {
                startVideo(for: anchor.identifier)
            }
            return
        }

        // Use async version with caching
        if let mainOverlay = await ARVideoOverlay.createMainOverlayAsync(for: anchor, targets: targets) {
            
            await MainActor.run {
                currentAnchorID = anchor.identifier
                playersByAnchor[anchor.identifier] = mainOverlay.player
                mainOverlay.player.isMuted = (isMuted == nil ? true : isMuted!)
                
                ARVideoControls.updateMuteIcon(isMuted: mainOverlay.player.isMuted)
                ARVideoControls.setControlsVisible(true)
                
                // Add node to parent
                parentNode.addChildNode(mainOverlay.node)
                
                print("💣 Video is playing (async, cached)")
            }
        } else {
            await MainActor.run {
                ARVideoControls.setControlsVisible(false)
            }
        }
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
        
        if player.timeControlStatus == .playing  || player.timeControlStatus == .waitingToPlayAtSpecifiedRate { return }
        
        print("✅ StartVideo")
        
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
