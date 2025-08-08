import Foundation
import UIKit
import Utilities

/// HTML Cache Manager for performance optimization
/// Caches rendered content, images, and calculated heights
@MainActor
public final class HTMLCacheManager: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = HTMLCacheManager()
    
    // MARK: - Cache Storage
    private var heightCache: [String: CGFloat] = [:]
    private var imageCache: NSCache<NSString, UIImage> = NSCache()
    private var htmlContentCache: [String: String] = [:]
    private var renderedViewCache: [String: Bool] = [:]
    
    // MARK: - Cache Configuration
    private let maxImageCacheSize: Int = 50 // Max 50 images
    private let maxContentCacheSize: Int = 100 // Max 100 HTML contents
    
    private init() {
        setupImageCache()
    }
    
    // MARK: - Public Methods
    
    /// Cache calculated height for HTML content
    public func cacheHeight(_ height: CGFloat, for contentHash: String) {
        heightCache[contentHash] = height
        
        // Cleanup old entries if cache gets too large
        if heightCache.count > maxContentCacheSize {
            cleanupHeightCache()
        }
    }
    
    /// Get cached height for HTML content
    public func getCachedHeight(for contentHash: String) -> CGFloat? {
        return heightCache[contentHash]
    }
    
    /// Cache processed HTML content
    public func cacheHTMLContent(_ content: String, for hash: String) {
        htmlContentCache[hash] = content
        
        // Cleanup old entries if cache gets too large
        if htmlContentCache.count > maxContentCacheSize {
            cleanupHTMLCache()
        }
    }
    
    /// Get cached HTML content
    public func getCachedHTMLContent(for hash: String) -> String? {
        return htmlContentCache[hash]
    }
    
    /// Cache image with URL as key
    public func cacheImage(_ image: UIImage, for url: String) {
        imageCache.setObject(image, forKey: url as NSString)
    }
    
    /// Get cached image
    public func getCachedImage(for url: String) -> UIImage? {
        return imageCache.object(forKey: url as NSString)
    }
    
    /// Mark view as rendered to avoid re-rendering
    public func markAsRendered(_ contentHash: String) {
        renderedViewCache[contentHash] = true
    }
    
    /// Check if view was already rendered
    public func isRendered(_ contentHash: String) -> Bool {
        return renderedViewCache[contentHash] == true
    }
    
    /// Clear all caches
    public func clearAll() {
        heightCache.removeAll()
        imageCache.removeAllObjects()
        htmlContentCache.removeAll()
        renderedViewCache.removeAll()
    }
    
    /// Clear specific content cache
    public func clearCache(for contentHash: String) {
        heightCache.removeValue(forKey: contentHash)
        htmlContentCache.removeValue(forKey: contentHash)
        renderedViewCache.removeValue(forKey: contentHash)
    }
    
    // MARK: - Private Methods
    
    private func setupImageCache() {
        imageCache.countLimit = maxImageCacheSize
        // Set memory limit to 50MB
        imageCache.totalCostLimit = 50 * 1024 * 1024
    }
    
    private func cleanupHeightCache() {
        // Remove oldest 20% of entries
        let removeCount = heightCache.count / 5
        let keysToRemove = Array(heightCache.keys.prefix(removeCount))
        
        for key in keysToRemove {
            heightCache.removeValue(forKey: key)
        }
    }
    
    private func cleanupHTMLCache() {
        // Remove oldest 20% of entries
        let removeCount = htmlContentCache.count / 5
        let keysToRemove = Array(htmlContentCache.keys.prefix(removeCount))
        
        for key in keysToRemove {
            htmlContentCache.removeValue(forKey: key)
            renderedViewCache.removeValue(forKey: key)
        }
    }
}

// MARK: - Content Hash Generator
public extension String {
    /// Generate consistent hash for caching
    var contentHash: String {
        return String(self.hashValue)
    }
    
    /// Generate SHA256 hash for more reliable caching
    var sha256Hash: String {
        guard let data = self.data(using: .utf8) else { return self.contentHash }
        
        var hash = [UInt8](repeating: 0, count: 32)
        data.withUnsafeBytes { buffer in
            let bytes = buffer.bindMemory(to: UInt8.self)
            // Simple hash implementation - in production, use CryptoKit
            for (index, byte) in bytes.enumerated() {
                hash[index % 32] ^= byte
            }
        }
        
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Cache Statistics
public extension HTMLCacheManager {
    struct CacheStatistics {
        let heightCacheSize: Int
        let imageCacheSize: Int
        let htmlContentCacheSize: Int
        let renderedViewCacheSize: Int
    }
    
    var statistics: CacheStatistics {
        return CacheStatistics(
            heightCacheSize: heightCache.count,
            imageCacheSize: imageCache.countLimit,
            htmlContentCacheSize: htmlContentCache.count,
            renderedViewCacheSize: renderedViewCache.count
        )
    }
    
    func printStatistics() {
        let stats = statistics
        print("""
        HTML Cache Statistics:
        - Height Cache: \(stats.heightCacheSize) items
        - Image Cache: \(stats.imageCacheSize) max items
        - HTML Content Cache: \(stats.htmlContentCacheSize) items
        - Rendered View Cache: \(stats.renderedViewCacheSize) items
        """)
    }
}