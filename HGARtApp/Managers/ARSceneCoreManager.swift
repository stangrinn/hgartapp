//
//  Untitled.swift
//  HGARt
//
//  Created by  Stanislav Grinshpun on 2025-04-13.
//

import Foundation
import ARKit
import UIKit
import SceneKit

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
        
    private func cachedImagePath(for targetName: String) -> URL {
        return cacheDirectory.appendingPathComponent("\(targetName).jpg")
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
        @param:
            - completion: A closure that is called when the targets are loaded and the session is started.
            - Returns: An array of targets.
    */
    func loadTargetsAndStartARSession(completion: @escaping ([ARTarget]) -> Void) {
        
        // Load config.json from the application bundle
        guard let url = Bundle.main.url(forResource: "ar-config", withExtension: "json") else {
            print("ARSessionManager: config.json not found in app bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            
            let decoded = try JSONDecoder().decode([String: [ARTarget]].self, from: data)
            
            self.targets = decoded["targets"] ?? []
            
            let group = DispatchGroup()
            
            referenceImagesQueue.sync { referenceImages.removeAll() }
            
            for target in self.targets {
                
                guard let imageUrl = URL(string: target.imageUrl) else {
                    print("ARSessionManager: Invalid image URL for target: \(target.name)")
                    continue
                }
                
                group.enter()
                
                let cachedPath = cachedImagePath(for: target.name)
                            
                // Check local cache
                if fileManager.fileExists(atPath: cachedPath.path),
                            let cachedImage = UIImage(contentsOfFile: cachedPath.path),
                            let cgImage = cachedImage.cgImage {
                                
                    addReferenceImage(cgImage, for: target)

                    group.leave()
                    continue  // Skip the 
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
                }.resume()
            }
            
            group.notify(queue: .main) {
                
                let images = self.referenceImagesQueue.sync { self.referenceImages }
                
                let configuration = ARImageTrackingConfiguration()
                
                configuration.trackingImages = images
                
                configuration.maximumNumberOfTrackedImages = images.count
                
                self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                
                completion(self.targets)
            }
            
        } catch {
            print("ARSessionManager: Failed to read bundled config: \(error.localizedDescription)")
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
