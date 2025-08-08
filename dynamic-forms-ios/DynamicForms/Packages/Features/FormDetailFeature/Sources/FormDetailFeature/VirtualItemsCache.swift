import Foundation
import Domain
import Utilities

/// Smart caching system for virtual form items with O(1) performance
/// Following Single Responsibility Principle with thread-safe operations
public final class VirtualItemsCache {
    
    // MARK: - Properties
    private let cache: ThreadSafeContainer<[String: CacheEntry]>
    private let maxCacheSize: Int
    private let logger: Logger
    
    // MARK: - Cache Entry
    private struct CacheEntry {
        let items: [VirtualFormItem]
        let timestamp: Date
        let hash: Int
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 30 // 30 seconds expiry
        }
    }
    
    // MARK: - Initialization
    public init(
        maxCacheSize: Int = 100,
        logger: Logger = ConsoleLogger()
    ) {
        self.cache = ThreadSafeContainer([:])
        self.maxCacheSize = maxCacheSize
        self.logger = logger
    }
    
    // MARK: - Public Methods
    
    /// Get cached virtual items (O(1) operation)
    public func getCachedItems(for cacheKey: VirtualItemsCacheKey) -> [VirtualFormItem]? {
        let key = cacheKey.stringKey
        let hash = cacheKey.hashValue
        
        let cachedEntry = cache.value[key]
        
        guard let entry = cachedEntry,
              !entry.isExpired,
              entry.hash == hash else {
            if cachedEntry?.isExpired == true {
                logger.debug("Cache entry expired for key: \(key)")
            }
            return nil
        }
        
        logger.debug("Cache hit for key: \(key)")
        return entry.items
    }
    
    /// Cache virtual items (O(1) operation)
    public func cacheItems(_ items: [VirtualFormItem], for cacheKey: VirtualItemsCacheKey) {
        let key = cacheKey.stringKey
        let hash = cacheKey.hashValue
        
        cache.mutate { [self] cacheDict in
            // Clean up expired entries if cache is getting large
            if cacheDict.count >= self.maxCacheSize {
                self.cleanupExpiredEntries(&cacheDict)
            }
            
            cacheDict[key] = CacheEntry(
                items: items,
                timestamp: Date(),
                hash: hash
            )
        }
        
        logger.debug("Cached \(items.count) items for key: \(key)")
    }
    
    /// Clear all cached items
    public func clearCache() {
        cache.setValue([:])
        logger.debug("Cache cleared")
    }
    
    /// Get cache statistics for debugging
    public func getCacheStats() -> VirtualItemsCacheStats {
        let cacheValue = cache.value
        let totalEntries = cacheValue.count
        let expiredEntries = cacheValue.values.filter { $0.isExpired }.count
        let validEntries = totalEntries - expiredEntries
        
        return VirtualItemsCacheStats(
            totalEntries: totalEntries,
            validEntries: validEntries,
            expiredEntries: expiredEntries,
            hitRatio: calculateHitRatio()
        )
    }
    
    // MARK: - Private Methods
    
    private func cleanupExpiredEntries(_ cacheDict: inout [String: CacheEntry]) {
        let beforeCount = cacheDict.count
        cacheDict = cacheDict.filter { !$0.value.isExpired }
        let afterCount = cacheDict.count
        
        if beforeCount != afterCount {
            logger.debug("Cleaned up \(beforeCount - afterCount) expired cache entries")
        }
    }
    
    private var hitCount: Int = 0
    private var missCount: Int = 0
    
    private func calculateHitRatio() -> Double {
        let total = hitCount + missCount
        guard total > 0 else { return 0.0 }
        return Double(hitCount) / Double(total)
    }
}

// MARK: - Cache Key
public struct VirtualItemsCacheKey: Hashable {
    let formId: String
    let fieldValuesHash: Int
    let sectionIndex: Int
    let editContext: EditContext
    let hasSuccessMessage: Bool
    let isAutoSaveEnabled: Bool
    
    public init(
        formId: String,
        fieldValues: [String: String],
        sectionIndex: Int,
        editContext: EditContext,
        hasSuccessMessage: Bool,
        isAutoSaveEnabled: Bool
    ) {
        self.formId = formId
        self.fieldValuesHash = fieldValues.hashValue
        self.sectionIndex = sectionIndex
        self.editContext = editContext
        self.hasSuccessMessage = hasSuccessMessage
        self.isAutoSaveEnabled = isAutoSaveEnabled
    }
    
    var stringKey: String {
        return "\(formId)_\(sectionIndex)_\(editContext)_\(hasSuccessMessage)_\(isAutoSaveEnabled)"
    }
}

// MARK: - Cache Statistics
public struct VirtualItemsCacheStats {
    public let totalEntries: Int
    public let validEntries: Int
    public let expiredEntries: Int
    public let hitRatio: Double
    
    public var debugDescription: String {
        return """
        VirtualItemsCache Statistics:
        - Total Entries: \(totalEntries)
        - Valid Entries: \(validEntries)
        - Expired Entries: \(expiredEntries)
        - Hit Ratio: \(String(format: "%.2f%%", hitRatio * 100))
        """
    }
}

// MARK: - Performance Monitor
public final class VirtualItemsPerformanceMonitor {
    
    private let logger: Logger
    private var generationTimes: [TimeInterval] = []
    private var renderTimes: [TimeInterval] = []
    
    public init(logger: Logger = ConsoleLogger()) {
        self.logger = logger
    }
    
    public func recordGenerationTime(_ time: TimeInterval) {
        generationTimes.append(time)
        
        // Keep only last 100 measurements
        if generationTimes.count > 100 {
            generationTimes.removeFirst()
        }
        
        if time > 0.016 { // 16ms threshold (60fps)
            logger.warning("Virtual items generation took \(time * 1000)ms - exceeds 16ms threshold")
        }
    }
    
    public func recordRenderTime(_ time: TimeInterval) {
        renderTimes.append(time)
        
        if renderTimes.count > 100 {
            renderTimes.removeFirst()
        }
        
        if time > 0.016 {
            logger.warning("Virtual items render took \(time * 1000)ms - exceeds 16ms threshold")
        }
    }
    
    public func getPerformanceStats() -> VirtualItemsPerformanceStats {
        let avgGeneration = generationTimes.isEmpty ? 0 : generationTimes.reduce(0, +) / Double(generationTimes.count)
        let avgRender = renderTimes.isEmpty ? 0 : renderTimes.reduce(0, +) / Double(renderTimes.count)
        let maxGeneration = generationTimes.max() ?? 0
        let maxRender = renderTimes.max() ?? 0
        
        return VirtualItemsPerformanceStats(
            averageGenerationTime: avgGeneration,
            averageRenderTime: avgRender,
            maxGenerationTime: maxGeneration,
            maxRenderTime: maxRender,
            measurementCount: generationTimes.count
        )
    }
}

// MARK: - Performance Statistics
public struct VirtualItemsPerformanceStats {
    public let averageGenerationTime: TimeInterval
    public let averageRenderTime: TimeInterval
    public let maxGenerationTime: TimeInterval
    public let maxRenderTime: TimeInterval
    public let measurementCount: Int
    
    public var debugDescription: String {
        return """
        VirtualItems Performance Statistics:
        - Average Generation Time: \(String(format: "%.2fms", averageGenerationTime * 1000))
        - Average Render Time: \(String(format: "%.2fms", averageRenderTime * 1000))
        - Max Generation Time: \(String(format: "%.2fms", maxGenerationTime * 1000))
        - Max Render Time: \(String(format: "%.2fms", maxRenderTime * 1000))
        - Measurements: \(measurementCount)
        """
    }
}