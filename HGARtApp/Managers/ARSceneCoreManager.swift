//
//  Untitled.swift
//  HGARt
//
//  Created by  Stanislav Grinshpun on 2025-04-13.
//

import Foundation
import ARKit
import CryptoKit
import UIKit
import SceneKit

enum ARTargetsError: Error {
    case configMissing
    case configInvalid
    case noTargetsLoaded
}

private extension Bundle {
    var appBuild: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }
}

class ARSceneCoreManager: NSObject {

    private var targets: [ARTarget] = []
    private var referenceImages: Set<ARReferenceImage> = []
    private let referenceImagesQueue = DispatchQueue(label: "ARSceneCoreManager.referenceImages")
    private let sceneView: ARSCNView
    
    private let fileManager = FileManager.default
    private lazy var cacheDirectory: URL = {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = paths[0].appendingPathComponent("ARImages", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        return cacheDir
    }()
        
    // Keyed by the image URL: Vendure issues a new URL when an asset is replaced.
    private func cachedImagePath(for imageUrl: String) -> URL {
        let digest = SHA256.hash(data: Data(imageUrl.utf8)).map { String(format: "%02x", $0) }.joined()
        return cacheDirectory.appendingPathComponent("\(digest).img")
    }

    private func purgeStaleCache(keeping targets: [ARTarget]) {
        let keep = Set(targets.map { cachedImagePath(for: $0.imageUrl).lastPathComponent })
        let files = (try? fileManager.contentsOfDirectory(atPath: cacheDirectory.path)) ?? []

        for file in files where !keep.contains(file) {
            try? fileManager.removeItem(at: cacheDirectory.appendingPathComponent(file))
        }
    }
    
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
    }

    private func addReferenceImage(_ cgImage: CGImage, for target: ARTarget) {
        let arImage = ARReferenceImage(cgImage, orientation: .up, physicalWidth: CGFloat(target.physicalWidth))
        arImage.name = target.name
        referenceImagesQueue.sync { _ = referenceImages.insert(arImage) }
    }
    
    /**
        Loads the targets from the config file and starts the session.
        - completion: Called on the main queue with the loaded targets, or an error when no target can be tracked.
    */
    func loadTargetsAndStartARSession(completion: @escaping (Result<[ARTarget], ARTargetsError>) -> Void) {
        
        // Load config.json from the application bundle
        guard let url = Bundle.main.url(forResource: "ar-config", withExtension: "json") else {
            print("ARSessionManager: config.json not found in app bundle")
            completion(.failure(.configMissing))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            
            let decoded = try JSONDecoder().decode([String: [ARTarget]].self, from: data)
            
            self.targets = decoded["targets"] ?? []
            
            purgeStaleCache(keeping: self.targets)
            
            let group = DispatchGroup()
            
            referenceImagesQueue.sync { referenceImages.removeAll() }
            
            for target in self.targets {
                
                guard let imageUrl = URL(string: target.imageUrl) else {
                    print("ARSessionManager: Invalid image URL for target: \(target.name)")
                    continue
                }
                
                group.enter()
                
                let cachedPath = cachedImagePath(for: target.imageUrl)
                            
                // Check local cache
                if fileManager.fileExists(atPath: cachedPath.path),
                            let cachedImage = UIImage(contentsOfFile: cachedPath.path),
                            let cgImage = cachedImage.cgImage {
                                
                    addReferenceImage(cgImage, for: target)

                    group.leave()
                    continue
                }
                
                // Use cache-buster only in DEBUG builds to avoid unnecessary reloads in production
                #if DEBUG
                    let effectiveImageURL = self.urlByAddingBuster(imageUrl.absoluteString) ?? imageUrl
                #else
                    let effectiveImageURL = imageUrl
                #endif
                
                let imageRequest = URLRequest(url: effectiveImageURL)
                
                URLSession.shared.dataTask(with: imageRequest) { [self] imageData, response, error in
                    
                    defer { group.leave() }
                    
                    if let error = error {
                        print("ARSessionManager: Failed to load image for target \(target.name): \(error.localizedDescription)")
                        return
                    }
                    
                    guard let imageData = imageData,
                          let uiImage = UIImage(data: imageData),
                          let cgImage = uiImage.cgImage else {
                            
                        print("ARSessionManager: Failed to create image for target \(target.name)")
                            
                        return
                    }
                    
                    addReferenceImage(cgImage, for: target)
                    
                    try? imageData.write(to: cachedPath, options: .atomic)
                }.resume()
            }
            
            group.notify(queue: .main) {
                
                let images = self.referenceImagesQueue.sync { self.referenceImages }
                
                guard !images.isEmpty else {
                    completion(.failure(.noTargetsLoaded))
                    return
                }
                
                let configuration = ARImageTrackingConfiguration()
                
                configuration.trackingImages = images
                
                configuration.maximumNumberOfTrackedImages = images.count
                
                self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                
                completion(.success(self.targets))
            }
            
        } catch {
            print("ARSessionManager: Failed to read bundled config: \(error.localizedDescription)")
            completion(.failure(.configInvalid))
        }
    }
    
    private func urlByAddingBuster(_ raw: String, key: String = "v") -> URL? {
        guard var comps = URLComponents(string: raw) else { return nil }
        var q = comps.queryItems ?? []
        // Use build number as a stable buster per build; fallback to timestamp during dev runs
        let value = Bundle.main.appBuild.isEmpty ? String(Int(Date().timeIntervalSince1970)) : Bundle.main.appBuild
        q.append(URLQueryItem(name: key, value: value))
        comps.queryItems = q
        return comps.url
    }
}
