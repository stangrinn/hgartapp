import Foundation

final class VideoCacheService: VideoCachingPort {
    func cachedVideoURL(for target: ARTarget, onProgress: @escaping (Double) -> Void) async throws -> URL {
        guard let remoteURL = URL(string: target.videoUrl) else {
            throw NSError(
                domain: "VideoCacheService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid video URL for target \(target.name)"]
            )
        }

        let fileManager = FileManager.default
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let folderURL = cacheDir.appendingPathComponent("ARVideos", isDirectory: true)
        let fileURL = folderURL.appendingPathComponent(remoteURL.lastPathComponent)

        if fileManager.fileExists(atPath: fileURL.path) {
            onProgress(1.0)
            return fileURL
        }

        if !fileManager.fileExists(atPath: folderURL.path) {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }

        onProgress(0.0)

        struct DownloadError: Error { let underlying: Error }

        do {
            let finalURL: URL = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
                final class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
                    let onProgress: (Double) -> Void
                    let destination: URL
                    let completion: (Result<URL, Error>) -> Void

                    init(
                        onProgress: @escaping (Double) -> Void,
                        destination: URL,
                        completion: @escaping (Result<URL, Error>) -> Void
                    ) {
                        self.onProgress = onProgress
                        self.destination = destination
                        self.completion = completion
                    }

                    func urlSession(
                        _ session: URLSession,
                        downloadTask: URLSessionDownloadTask,
                        didWriteData bytesWritten: Int64,
                        totalBytesWritten: Int64,
                        totalBytesExpectedToWrite: Int64
                    ) {
                        guard totalBytesExpectedToWrite > 0 else { return }
                        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                        DispatchQueue.main.async { self.onProgress(progress) }
                    }

                    func urlSession(
                        _ session: URLSession,
                        downloadTask: URLSessionDownloadTask,
                        didFinishDownloadingTo location: URL
                    ) {
                        do {
                            let fm = FileManager.default
                            let dir = destination.deletingLastPathComponent()

                            if !fm.fileExists(atPath: dir.path) {
                                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                            }

                            if fm.fileExists(atPath: destination.path) {
                                try fm.removeItem(at: destination)
                            }

                            try fm.moveItem(at: location, to: destination)
                            DispatchQueue.main.async { self.onProgress(1.0) }
                            completion(.success(destination))
                        } catch {
                            completion(.failure(error))
                        }
                    }

                    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
                        if let error {
                            completion(.failure(error))
                        }
                    }
                }

                let cfg = URLSessionConfiguration.default
                cfg.waitsForConnectivity = true
                cfg.allowsExpensiveNetworkAccess = true
                cfg.allowsConstrainedNetworkAccess = true

                let delegate = DownloadDelegate(onProgress: onProgress, destination: fileURL) { result in
                    switch result {
                    case .success(let url):
                        cont.resume(returning: url)
                    case .failure(let err):
                        cont.resume(throwing: DownloadError(underlying: err))
                    }
                }

                let session = URLSession(configuration: cfg, delegate: delegate, delegateQueue: nil)
                let task = session.downloadTask(with: remoteURL)
                task.resume()
            }

            return finalURL
        } catch {
            let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)

            if !fileManager.fileExists(atPath: folderURL.path) {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            }

            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }

            try fileManager.moveItem(at: tempURL, to: fileURL)
            onProgress(1.0)
            return fileURL
        }
    }
}
