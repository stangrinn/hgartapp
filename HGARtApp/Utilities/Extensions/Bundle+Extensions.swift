//
//  Bundle+Extensions.swift
//  HGArt
//
//  Created by Stanislav Grinshpun on 2025-10-08.
//

import Foundation

extension Bundle {
    
    /// Get app build number
    var appBuild: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }
    
    /// Get app version
    var appVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    
    /// Check if running in App Clip
    var isRunningInAppClip: Bool {
        if Bundle.main.object(forInfoDictionaryKey: "NSAppClip") != nil {
            return true
        }
        if let bundleId = Bundle.main.bundleIdentifier, bundleId.contains("Clip") {
            return true
        }
        return false
    }
}
