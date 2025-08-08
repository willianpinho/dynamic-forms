import Foundation

/// Enum defining conflict resolution strategies for form entry operations
/// Following Clean Code principles with clear naming and single responsibility
public enum ConflictResolutionStrategy: Sendable {
    case overwrite  // Overwrite existing entry with new data
    case merge      // Merge local and remote changes intelligently
    case fail       // Fail operation with conflict error
    case createNew  // Create new entry with different ID
    case skip       // Skip the operation for this entry
    
    /// Default strategy for save operations
    public static let defaultSave: ConflictResolutionStrategy = .overwrite
    
    /// Default strategy for auto-save operations
    public static let defaultAutoSave: ConflictResolutionStrategy = .merge
}