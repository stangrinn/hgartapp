//
//  VideoCacheServiceProtocol.swift
//  HGArt
//
//  Created by Stanislav Grinshpun on 2025-10-08.
//

import Foundation

/// Protocol for video caching service
/// Manages downloading and caching of AR video content
protocol VideoCacheServiceProtocol {
    
    /// Get cached URL for video or download if not cached
    /// - Parameter target: AR target containing video URL
    /// - Returns: Local file URL for the cached video
    /// - Throws: VideoCacheError if download or caching fails
    func getCachedURL(for target: ARTarget) async throws -> URL
    
    /// Check if video is already cached locally
    /// - Parameter target: AR target to check
    /// - Returns: True if video exists in cache
    func isCached(target: ARTarget) -> Bool
    
    /// Clear all cached videos
    /// - Throws: Error if cache directory cannot be removed
    func clearCache() throws
    
    /// Get size of cache directory
    /// - Returns: Size in bytes
    func getCacheSize() -> UInt64
}

/// Errors that can occur during video caching
enum VideoCacheError: LocalizedError {
    case invalidURL
    case downloadFailed(Error)
    case fileNotFound
    case cachingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid video URL"
        case .downloadFailed(let error):
            return "Failed to download video: \(error.localizedDescription)"
        case .fileNotFound:
            return "Video file not found in cache"
        case .cachingFailed(let error):
            return "Failed to cache video: \(error.localizedDescription)"
        }
    }
}
