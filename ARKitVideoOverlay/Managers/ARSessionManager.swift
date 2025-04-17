//
//  Untitled.swift
//  ARKitVideoOverlay
//
//  Created by Web TL AE Stanislav Grinshpun on 2025-04-13.
//

import Foundation
import ARKit
import UIKit
import SceneKit

class ARSessionManager: NSObject {
    private var targets: [ARTarget] = []
    private var referenceImages: Set<ARReferenceImage> = []
    private let sceneView: ARSCNView
    private let CONFIG_URL: String = "https://helenagrinshpun.art/assets/config.json"
    
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
    }
    
    func loadTargetsAndStartSession(completion: @escaping ([ARTarget]) -> Void) {
        
        guard let url = URL(string: CONFIG_URL) else {
            print("ARSessionManager: Invalid CONFIG_URL")
            return
        }
    
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                print("ARSessionManager: Failed to fetch config: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode([String: [ARTarget]].self, from: data)
                self.targets = decoded["targets"] ?? []
                
                let group = DispatchGroup()
                
                for target in self.targets {
                    guard let imageUrl = URL(string: target.imageUrl) else {
                        print("ARSessionManager: Invalid image URL for target: \(target.name)")
                        continue
                    }
                    
                    group.enter()
                    
                    URLSession.shared.dataTask(with: imageUrl) { imageData, _, error in
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
                print("ARSessionManager: Failed to decode config: \(error.localizedDescription)")
            }
        }.resume()
    }
}
