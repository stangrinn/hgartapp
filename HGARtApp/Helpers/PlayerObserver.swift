import AVFoundation
import Foundation

/// Observes the current looper item and buffering; playback decisions belong to the manager.
class PlayerObserver: NSObject {
    enum State { case buffering, playing, paused, failed }
    let player: AVPlayer
    var stateDidChange: ((State) -> Void)?
    private var observations: [NSKeyValueObservation] = []
    private var itemObservation: NSKeyValueObservation?
    private var failureToken: NSObjectProtocol?
    private var isObserving = false

    init(player: AVPlayer) {
        self.player = player
        super.init()
        startObserving()
    }

    func startObserving() {
        guard !isObserving else { return }
        isObserving = true
        observations = [
            player.observe(\.currentItem, options: [.initial, .new]) { [weak self] player, _ in
                DispatchQueue.main.async { [weak self, weak player] in
                    guard let self, self.isObserving else { return }
                    self.observeItem(player?.currentItem)
                }
            },
            player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] _, _ in self?.publish() },
            player.observe(\.status, options: [.new]) { [weak self] _, _ in self?.publish() }
        ]
    }

    private func observeItem(_ item: AVPlayerItem?) {
        itemObservation?.invalidate()
        if let failureToken { NotificationCenter.default.removeObserver(failureToken) }
        failureToken = nil
        item?.preferredForwardBufferDuration = 3
        item?.canUseNetworkResourcesForLiveStreamingWhilePaused = false
        itemObservation = item?.observe(\.status, options: [.initial, .new]) { [weak self] _, _ in self?.publish() }
        if let item {
            failureToken = NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime,
                object: item, queue: .main) { [weak self] _ in self?.publish(failed: true) }
        }
        publish()
    }

    private func publish(failed: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isObserving else { return }
            let state: State
            if failed || self.player.status == .failed || self.player.currentItem?.status == .failed {
                state = .failed
            } else if self.player.timeControlStatus == .playing {
                state = .playing
            } else if self.player.timeControlStatus == .waitingToPlayAtSpecifiedRate || self.player.currentItem?.status == .unknown {
                state = .buffering
            } else {
                state = .paused
            }
            self.stateDidChange?(state)
        }
    }

    func stopObserving() {
        isObserving = false
        observations.forEach { $0.invalidate() }
        observations.removeAll()
        itemObservation?.invalidate()
        itemObservation = nil
        if let failureToken { NotificationCenter.default.removeObserver(failureToken) }
        failureToken = nil
    }

    // Retained for explicit KVO dispatch; never starts playback on readiness.
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        publish()
    }

    deinit { stopObserving() }
}
