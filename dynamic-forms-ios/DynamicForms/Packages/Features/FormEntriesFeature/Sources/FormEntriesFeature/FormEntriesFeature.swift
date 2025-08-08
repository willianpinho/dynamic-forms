import Foundation
import Domain

/// Entry point for FormEntriesFeature module
/// Provides access to feature components and types for form entry management
public struct FormEntriesFeature {
    
    /// Feature identifier
    public static let identifier = "FormEntriesFeature"
    
    /// Feature version
    public static let version = "1.0.0"
    
    /// Feature capabilities
    public static func getCapabilities() -> [String] {
        return [
            "📝 Entry Management (Drafts, Submitted, Edit Drafts)",
            "📊 Statistics and Analytics",
            "🔍 Search and Filtering",
            "🗑️ Bulk Operations",
            "📈 Progress Tracking",
            "⚡ Real-time Updates",
            "🎨 Modern SwiftUI Interface",
            "🔄 State Management with Combine"
        ]
    }
    
    /// Performance information
    public static func getPerformanceInfo() -> String {
        return """
        FormEntriesFeature Performance:
        ✅ Efficient filtering with O(n log n) sorting
        ✅ Lazy loading for large entry lists
        ✅ Real-time search with debouncing
        ✅ Memory-efficient entry cards
        ✅ Optimized state management
        ✅ Background operations support
        """
    }
}

// MARK: - Public Exports
// Note: Using direct references to avoid naming conflicts

// MARK: - Feature Demo Data
public extension FormEntriesFeature {
    
    /// Generate demo entries for testing and previews
    static func generateDemoEntries(for formId: String, count: Int = 10) -> [FormEntry] {
        var entries: [FormEntry] = []
        
        for i in 0..<count {
            let entryId = "demo-entry-\(i)"
            let isDraft = i % 3 == 0
            let isComplete = !isDraft && i % 2 == 0
            let isEditDraft = isDraft && i % 5 == 0
            
            let entry = FormEntry(
                id: entryId,
                formId: formId,
                sourceEntryId: isEditDraft ? "original-\(i)" : nil,
                fieldValues: generateDemoFieldValues(for: i),
                createdAt: Date().addingTimeInterval(-TimeInterval(i * 3600)), // Spread over hours
                updatedAt: Date().addingTimeInterval(-TimeInterval(i * 600)), // Recent updates
                isComplete: isComplete,
                isDraft: isDraft
            )
            
            entries.append(entry)
        }
        
        return entries
    }
    
    private static func generateDemoFieldValues(for index: Int) -> [String: String] {
        let names = ["João", "Maria", "Pedro", "Ana", "Carlos", "Lucia", "Rafael", "Fernanda"]
        let surnames = ["Silva", "Santos", "Oliveira", "Costa", "Ferreira", "Pereira", "Lima", "Alves"]
        
        return [
            "name": "\(names[index % names.count]) \(surnames[index % surnames.count])",
            "email": "\(names[index % names.count].lowercased())@example.com",
            "age": "\(20 + index % 40)",
            "city": "São Paulo"
        ]
    }
    
    /// Generate demo statistics
    static func generateDemoStatistics() -> EntryStatistics {
        return EntryStatistics(
            totalEntries: 25,
            draftEntries: 8,
            editDraftEntries: 3,
            completedEntries: 12,
            submittedEntries: 2,
            lastUpdated: Date()
        )
    }
}