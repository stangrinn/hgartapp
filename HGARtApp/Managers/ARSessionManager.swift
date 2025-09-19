//
//  Untitled.swift
//  HGARt
//
//  Created by Web TL AE Stanislav Grinshpun on 2025-04-13.
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

class ARSessionManager: NSObject {

    private var targets: [ARTarget] = []
    private var referenceImages: Set<ARReferenceImage> = []
    private let sceneView: ARSCNView
    
    
    
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
    }
    
    /**
        Loads the targets from the config file and starts the session.
        @param:
            - completion: A closure that is called when the targets are loaded and the session is started.
            - Returns: An array of targets.
    */
    func loadTargetsAndStartSession(completion: @escaping ([ARTarget]) -> Void) {
        
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
            self.referenceImages.removeAll()
            
            for target in self.targets {
                guard let imageUrl = URL(string: target.imageUrl) else {
                    print("ARSessionManager: Invalid image URL for target: \(target.name)")
                    continue
                }
                
                group.enter()
                
                // Keep cache-busting for images to avoid CDN-propagation issues during development
                let effectiveImageURL = self.urlByAddingBuster(imageUrl.absoluteString) ?? imageUrl
                let imageRequest = self.nonCachingRequest(url: effectiveImageURL)
                
                self.noCacheSession.dataTask(with: imageRequest) { imageData, response, error in
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
                    
                    let arImage = ARReferenceImage(cgImage, orientation: .up, physicalWidth: CGFloat(target.physicalWidth))
                    arImage.name = target.name
                    self.referenceImages.insert(arImage)
                    
                }.resume()
            }
            
            group.notify(queue: .main) {
                let configuration = ARImageTrackingConfiguration()
                configuration.trackingImages = self.referenceImages
                configuration.maximumNumberOfTrackedImages = self.referenceImages.count
                
                self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                
                completion(self.targets)
            }
            
        } catch {
            print("ARSessionManager: Failed to read bundled config: \(error.localizedDescription)")
        }
    }
    
    private lazy var noCacheSession: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        cfg.urlCache = nil
        cfg.httpAdditionalHeaders = [
            "Cache-Control": "no-cache",
            "Pragma": "no-cache"
        ]
        return URLSession(configuration: cfg)
    }()

    private func urlByAddingBuster(_ raw: String, key: String = "v") -> URL? {
        guard var comps = URLComponents(string: raw) else { return nil }
        var q = comps.queryItems ?? []
        // Use build number as a stable buster per build; fallback to timestamp during dev runs
        let value = Bundle.main.appBuild.isEmpty ? String(Int(Date().timeIntervalSince1970)) : Bundle.main.appBuild
        q.append(URLQueryItem(name: key, value: value))
        comps.queryItems = q
        return comps.url
    }

    private func nonCachingRequest(url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        req.setValue("no-cache", forHTTPHeaderField: "Pragma")
        return req
    }
}
