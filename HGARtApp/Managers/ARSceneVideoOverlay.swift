import ARKit
import AVFoundation
import SceneKit
import SpriteKit

class ARSceneVideoOverlay: NSObject {
    private var observers: [String: PlayerObserver] = [:]
    private var loopers: [String: AVPlayerLooper] = [:]
    private var looperObservations: [String: NSKeyValueObservation] = [:]
    private var stateHandlers: [String: (PlayerObserver.State) -> Void] = [:]
    private var players: [String: AVQueuePlayer] = [:]
    private var targetsByName: [String: ARTarget] = [:]
    private var videoNodes: [String: SKVideoNode] = [:]

    /// Builds the remote item immediately. AVFoundation buffers only what playback needs.
    func makeStreamingItem(for target: ARTarget) -> AVPlayerItem? {
        guard let url = URL(string: target.videoUrl), url.scheme == "https", url.host != nil else { return nil }
        let item = AVPlayerItem(asset: AVURLAsset(url: url))
        item.preferredForwardBufferDuration = 3
        item.canUseNetworkResourcesForLiveStreamingWhilePaused = false
        return item
    }

    @MainActor
    func createMainOverlayAsync(for imageAnchor: ARImageAnchor, targets: [ARTarget],
                                parentNode: SCNNode) async -> AVQueuePlayer? {
        guard let name = imageAnchor.referenceImage.name,
              let target = targets.first(where: { $0.name == name }),
              let item = makeStreamingItem(for: target),
              let plane = parentNode.childNodes.first?.geometry as? SCNPlane else { return nil }
        let player: AVQueuePlayer
        if let existing = players[name] {
            player = existing
        } else {
            player = AVQueuePlayer()
            player.automaticallyWaitsToMinimizeStalling = true
            installLoop(name: name, player: player, item: item)
            players[name] = player
            targetsByName[name] = target
        }
        let sceneSize = CGSize(width: 1280, height: 720)
        let scene = SKScene(size: sceneSize)
        scene.backgroundColor = .clear
        scene.scaleMode = .aspectFit
        let node = SKVideoNode(avPlayer: player)
        node.yScale = -1
        node.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        node.size = sceneSize
        scene.addChild(node)
        videoNodes[name] = node

        let panel = SKShapeNode(rectOf: CGSize(width: sceneSize.width * 0.85, height: 120), cornerRadius: 20)
        panel.fillColor = UIColor.black.withAlphaComponent(0.7)
        panel.strokeColor = .clear
        panel.position = node.position
        panel.zPosition = 1
        scene.addChild(panel)
        let label = SKLabelNode(text: "buffering…")
        label.fontName = "Arial"
        label.fontColor = .white
        label.fontSize = 44
        label.verticalAlignmentMode = .center
        label.yScale = -1
        panel.addChild(label)

        observers[name]?.stopObserving()
        let observer = PlayerObserver(player: player)
        let handleState: (PlayerObserver.State) -> Void = { [weak panel, weak label] state in
            switch state {
            case .playing:
                panel?.isHidden = true
            case .buffering:
                panel?.isHidden = false
                label?.text = "buffering…"
                label?.fontColor = .white
            case .failed:
                panel?.isHidden = false
                label?.text = "connection error"
                label?.fontColor = .red
            case .paused:
                break
            }
        }
        stateHandlers[name] = handleState
        observer.stateDidChange = handleState
        observers[name] = observer
        plane.firstMaterial?.diffuse.contents = scene
        plane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Identity
        // Neither the scene nor the observer autoplays: the manager checks tracking/foreground.
        return player
    }

    @MainActor
    func prepareToPlay(_ player: AVQueuePlayer) {
        guard let name = players.first(where: { $0.value === player })?.key,
              let target = targetsByName[name], let item = makeStreamingItem(for: target) else { return }
        if let existing = loopers[name] {
            guard existing.status == .failed else { return }
            existing.disableLooping()
            player.removeAllItems()
        }
        installLoop(name: name, player: player, item: item)
    }

    @MainActor
    private func installLoop(name: String, player: AVQueuePlayer, item: AVPlayerItem) {
        let looper = AVPlayerLooper(player: player, templateItem: item)
        loopers[name] = looper
        // The looper may fail before inserting its first item (for example, HTTP 404).
        looperObservations[name] = looper.observe(\.status, options: [.initial, .new]) { [weak self] looper, _ in
            guard looper.status == .failed else { return }
            DispatchQueue.main.async { [weak self, weak looper] in
                guard let self, let looper, self.loopers[name] === looper else { return }
                self.stateHandlers[name]?(.failed)
            }
        }
    }

    @MainActor
    func suspendStreams() {
        loopers.values.forEach { $0.disableLooping() }
        loopers.removeAll()
        looperObservations.removeAll()
        for player in players.values {
            player.pause()
            player.removeAllItems()
        }
    }
}
