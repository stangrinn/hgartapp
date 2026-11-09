import Foundation

protocol TargetLoadingPort {
    func loadTargets() async throws -> [ARTarget]
}

protocol ARSessionLifecyclePort: AnyObject {
    func startSession(with targets: [ARTarget]) async throws
    func stopSession()
}

protocol VideoCachingPort {
    func cachedVideoURL(for target: ARTarget, onProgress: @escaping (Double) -> Void) async throws -> URL
}
