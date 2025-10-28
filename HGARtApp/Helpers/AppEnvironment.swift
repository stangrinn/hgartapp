//
//  AppEnvironment.swift
//  HGArt
//
//  Created by Stanislav Grinshpun on 2025-10-19.
//

import CoreMedia
import Foundation
import SceneKit
import SpriteKit

enum AppEnvironment {
    /// Determines whether the app is running as an App Clip
    static var isRunningInAppClip: Bool {
        if Bundle.main.object(forInfoDictionaryKey: "NSAppClip") != nil {
            return true
        }
        if let bundleId = Bundle.main.bundleIdentifier,
           bundleId.contains("Clip") {
            return true
        }
        return false
    }
    
    /// Returns the preloader resource name based on environment
    static var preloaderResourceName: String {
//        isRunningInAppClip ? "Loader-kids" : "Loader"
        "Loader-kids"
    }
    
    /// Returns the background color based on environment
    static var preloaderBackgroundColor: UIColor {
        if isRunningInAppClip {
            return UIColor(red: 254 / 255, green: 250 / 255, blue: 235 / 255, alpha: 1.0)
        } else {
            return UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        }
    }
}
