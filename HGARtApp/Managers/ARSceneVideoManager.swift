import UIKit
import AVFoundation
import SceneKit
import ARKit

@MainActor
class ARSceneVideoManager {
    private var trackedAnchors: Set<UUID> = []

    func updateTracking(_ isTracked: Bool, for anchorID: UUID) {
        if isTracked {
            trackedAnchors.insert(anchorID)
        } else {
            trackedAnchors.remove(anchorID)
        }
    }

    func isTracking(_ anchorID: UUID) -> Bool {
        trackedAnchors.contains(anchorID)
    }
    
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
    func createOverlayVideoPlaneAsync(for anchor: ARImageAnchor,
                                      targets: [ARTarget],
                                      parentNode: SCNNode,
                                      onProgress: @escaping (Double) -> Void) async -> Bool {
        
        await prepareVideo(for: anchor.identifier) {
            await self.arVideoOverlay.createMainOverlayAsync(
                for: anchor, targets: targets, parentNode: parentNode, onProgress: onProgress
            )
        }
    }

    /// Loading can finish after tracking changes; decide playback only after the await.
    func prepareVideo(for anchorID: UUID, loadPlayer: () async -> AVQueuePlayer?) async -> Bool {
        if playersByAnchor[anchorID] != nil {
            startVideo(for: anchorID)
            return true
        }
        guard let player = await loadPlayer() else {
            if currentAnchorID == nil { controls.setControlsVisible(false) }
            return false
        }
        playersByAnchor[anchorID] = player
        player.isMuted = isMuted ?? true
        if isTracking(anchorID) {
            controls.updateMuteIcon(isMuted: player.isMuted)
            startVideo(for: anchorID)
        } else {
            player.pause()
        }
        return true
    }

    @MainActor
    func stopVideo(for anchorID: UUID) {
        
        if let player: AVPlayer = playersByAnchor[anchorID] {
            
            player.pause()
            
            player.seek(to: .zero)
            
            print("👋 Video is not Playing")
        }
        
        if currentAnchorID == anchorID { clearCurrentAnchor() }
        
    
    }
    
    @MainActor
    func startVideo(for anchorID: UUID) {
        
        guard isTracking(anchorID), let player = playersByAnchor[anchorID] else { return }
        
        if player.timeControlStatus == .playing  || player.timeControlStatus == .waitingToPlayAtSpecifiedRate { return }
        
        print("✅ StartVideo player is playing")
        
        player.play()
        
        currentAnchorID = anchorID
        
        self.controls.setControlsVisible(true)
        
    }
    
    @MainActor
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
