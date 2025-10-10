import UIKit
import AVFoundation
import SceneKit
import ARKit

class ARSceneVideoManager {
    
    private var playersByAnchor: [UUID: AVQueuePlayer] = [:]
    
    private var currentAnchorID: UUID?
    
    private var isPlaying: Bool {
        
        guard let currentAnchorID = currentAnchorID, let player = playersByAnchor[currentAnchorID] else { return false }
        
        return player.timeControlStatus == .playing
    }
    
    private var isMuted: Bool? = nil
    
    private weak var view: UIView?
    
    private var controls: ARVideoControls
    
    private var arVideoOverlay: ARSceneVideoOverlay
    
    init(view: UIView) {
        self.view = view
        
        self.controls = ARVideoControls()
        
        self.arVideoOverlay = ARSceneVideoOverlay()
        
        self.controls.setup(view: self.view!,
                                    target: self,
                                    muteSelector: #selector(toggleMute),
                                    isMuted: { [weak self] in self?.isMuted ?? false },
                                    isPlaying: { [weak self] in self?.isPlaying ?? false })
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
        if let mainOverlay = await self.arVideoOverlay.createMainOverlayAsync(for: anchor, targets: targets) {
            
            await MainActor.run {
                
                currentAnchorID = anchor.identifier
                
                playersByAnchor[anchor.identifier] = mainOverlay.player
                
                mainOverlay.player.isMuted = (isMuted == nil ? true : isMuted!)
                
                self.controls.updateMuteIcon(isMuted: mainOverlay.player.isMuted)
                
                self.controls.setControlsVisible(true)
                
                // Add node to parent
                parentNode.addChildNode(mainOverlay.node)
                
                print("📽️ Video is playing (async, cached)")
            }
        } else {
            await MainActor.run {
                self.controls.setControlsVisible(false)
            }
        }
    }

    func stopVideo(for anchorID: UUID) {
        
        if let player: AVPlayer = playersByAnchor[anchorID] {
            
            player.pause()
            
            player.seek(to: .zero)
            
            print("👋 Video is not Playing")
        }
        
        self.controls.setControlsVisible(false)
        
        clearCurrentAnchor()
        
    
    }
    
    func startVideo(for anchorID: UUID) {
        
        guard let player = playersByAnchor[anchorID] else { return }
        
        if player.timeControlStatus == .playing  || player.timeControlStatus == .waitingToPlayAtSpecifiedRate { return }
        
        print("✅ StartVideo player is playing")
        
        player.play()
        
        currentAnchorID = anchorID
        
        self.controls.setControlsVisible(true)
        
    }
    
    private func clearCurrentAnchor() {
        
        currentAnchorID = nil
        
        self.controls.setControlsVisible(false)
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
        
        self.controls.updateMuteIcon(isMuted: player.isMuted)
    }

}
