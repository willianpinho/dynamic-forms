import Foundation
import Domain

/// Test generator for infinite fields to demonstrate O(1) performance
/// Following Single Responsibility Principle with performance benchmarking
public final class InfiniteFieldsTestGenerator {
    
    // MARK: - Test Configuration
    public struct TestConfiguration {
        public let fieldCount: Int
        public let sectionCount: Int
        public let fieldsPerSection: Int
        public let includeComplexFields: Bool
        public let useRandomContent: Bool
        
        public init(
            fieldCount: Int = 10000,
            sectionCount: Int = 100,
            fieldsPerSection: Int = 100,
            includeComplexFields: Bool = true,
            useRandomContent: Bool = false
        ) {
            self.fieldCount = fieldCount
            self.sectionCount = sectionCount
            self.fieldsPerSection = fieldsPerSection
            self.includeComplexFields = includeComplexFields
            self.useRandomContent = useRandomContent
        }
        
        public static let massive = TestConfiguration(
            fieldCount: 50000,
            sectionCount: 500,
            fieldsPerSection: 100,
            includeComplexFields: true,
            useRandomContent: true
        )
        
        public static let moderate = TestConfiguration(
            fieldCount: 5000,
            sectionCount: 50,
            fieldsPerSection: 100,
            includeComplexFields: true,
            useRandomContent: false
        )
        
        public static let standard = TestConfiguration(
            fieldCount: 1000,
            sectionCount: 10,
            fieldsPerSection: 100,
            includeComplexFields: false,
            useRandomContent: false
        )
    }
    
    // MARK: - Public Methods
    
    /// Generate a test form with massive number of fields to test virtual scrolling
    public static func generateInfiniteFieldsForm(
        configuration: TestConfiguration = .moderate
    ) -> DynamicForm {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        var fields: [FormField] = []
        var sections: [FormSection] = []
        
        // Generate fields in batches for better memory management
        for sectionIndex in 0..<configuration.sectionCount {
            let sectionFields = generateFieldsForSection(
                sectionIndex: sectionIndex,
                configuration: configuration
            )
            fields.append(contentsOf: sectionFields)
            
            // Create section
            let section = FormSection(
                uuid: "section-\(sectionIndex)",
                title: generateSectionTitle(sectionIndex: sectionIndex, configuration: configuration),
                from: sectionIndex * configuration.fieldsPerSection,
                to: min((sectionIndex + 1) * configuration.fieldsPerSection - 1, configuration.fieldCount - 1),
                index: sectionIndex
            )
            sections.append(section)
        }
        
        // Add remaining fields if any
        let remainingFieldsCount = configuration.fieldCount - (configuration.sectionCount * configuration.fieldsPerSection)
        if remainingFieldsCount > 0 {
            let remainingFields = generateRemainingFields(
                count: remainingFieldsCount,
                startIndex: configuration.sectionCount * configuration.fieldsPerSection,
                configuration: configuration
            )
            fields.append(contentsOf: remainingFields)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let generationTime = endTime - startTime
        
        print("Generated \(fields.count) fields and \(sections.count) sections in \(String(format: "%.2fms", generationTime * 1000))")
        
        return DynamicForm(
            id: "infinite-fields-test-\(configuration.fieldCount)",
            title: "Infinite Fields Test (\(configuration.fieldCount) fields)",
            fields: fields,
            sections: sections
        )
    }
    
    /// Benchmark virtual scrolling performance with different field counts
    public static func benchmarkVirtualScrollingPerformance() -> VirtualScrollingBenchmarkResults {
        var results: [VirtualScrollingBenchmarkResult] = []
        
        let testConfigurations: [TestConfiguration] = [
            .standard,
            .moderate,
            TestConfiguration(fieldCount: 20000, sectionCount: 200, fieldsPerSection: 100),
            .massive
        ]
        
        for config in testConfigurations {
            let result = benchmarkConfiguration(config)
            results.append(result)
        }
        
        return VirtualScrollingBenchmarkResults(results: results)
    }
    
    // MARK: - Private Methods
    
    private static func generateFieldsForSection(
        sectionIndex: Int,
        configuration: TestConfiguration
    ) -> [FormField] {
        var fields: [FormField] = []
        
        for fieldIndex in 0..<configuration.fieldsPerSection {
            let globalFieldIndex = sectionIndex * configuration.fieldsPerSection + fieldIndex
            if globalFieldIndex >= configuration.fieldCount { break }
            
            let field = generateField(
                index: globalFieldIndex,
                sectionIndex: sectionIndex,
                configuration: configuration
            )
            fields.append(field)
        }
        
        return fields
    }
    
    private static func generateField(
        index: Int,
        sectionIndex: Int,
        configuration: TestConfiguration
    ) -> FormField {
        let fieldType = selectFieldType(index: index, configuration: configuration)
        let uuid = "field-\(index)"
        let name = "field_\(index)"
        let label = generateFieldLabel(index: index, type: fieldType, configuration: configuration)
        let required = index % 3 == 0 // Every 3rd field is required
        
        switch fieldType {
        case .text, .email, .password, .textarea, .file:
            return FormField(
                uuid: uuid,
                type: fieldType,
                name: name,
                label: label,
                required: required
            )
        case .number:
            return FormField(
                uuid: uuid,
                type: .number,
                name: name,
                label: label,
                required: required
            )
        case .dropdown, .radio:
            return FormField(
                uuid: uuid,
                type: fieldType,
                name: name,
                label: label,
                required: required,
                options: generateFieldOptions(index: index)
            )
        case .description:
            return FormField(
                uuid: uuid,
                type: .description,
                name: name,
                label: label,
                required: false,
                value: generateDescriptionContent(index: index, configuration: configuration)
            )
        case .checkbox:
            return FormField(
                uuid: uuid,
                type: .checkbox,
                name: name,
                label: label,
                required: required,
                options: generateFieldOptions(index: index)
            )
        case .date:
            return FormField(
                uuid: uuid,
                type: .date,
                name: name,
                label: label,
                required: required
            )
        }
    }
    
    private static func selectFieldType(index: Int, configuration: TestConfiguration) -> FieldType {
        if !configuration.includeComplexFields {
            return index % 2 == 0 ? .text : .number
        }
        
        let allTypes: [FieldType] = [.text, .number, .dropdown, .description, .email, .textarea, .checkbox, .date, .file]
        return allTypes[index % allTypes.count]
    }
    
    private static func generateFieldLabel(
        index: Int,
        type: FieldType,
        configuration: TestConfiguration
    ) -> String {
        if configuration.useRandomContent {
            return "Random \(type.displayName) Field \(index)"
        }
        
        switch type {
        case .text:
            return "Text Field \(index)"
        case .number:
            return "Number Field \(index)"
        case .dropdown:
            return "Dropdown Field \(index)"
        case .description:
            return "Description \(index)"
        case .email:
            return "Email Field \(index)"
        case .textarea:
            return "Textarea Field \(index)"
        case .checkbox:
            return "Checkbox Field \(index)"
        case .date:
            return "Date Field \(index)"
        default:
            return "\(type.displayName) Field \(index)"
        }
    }
    
    private static func generateFieldOptions(index: Int) -> [FieldOption] {
        let optionCount = (index % 5) + 2 // 2-6 options
        return (0..<optionCount).map { optionIndex in
            FieldOption(
                label: "Option \(optionIndex + 1)",
                value: "option_\(index)_\(optionIndex)"
            )
        }
    }
    
    private static func generateDescriptionContent(
        index: Int,
        configuration: TestConfiguration
    ) -> String {
        if configuration.useRandomContent {
            return "<h3>Dynamic Description \(index)</h3><p>This is a <strong>dynamic description</strong> field with HTML content for testing purposes. Field index: \(index)</p><ul><li>Performance testing</li><li>Virtual scrolling</li><li>Memory optimization</li></ul>"
        }
        
        return "<h3>Section Description \(index)</h3><p>This is description field \(index) with basic HTML formatting.</p>"
    }
    
    private static func generateSectionTitle(
        sectionIndex: Int,
        configuration: TestConfiguration
    ) -> String {
        if configuration.useRandomContent {
            return "<h2>Dynamic Section \(sectionIndex + 1)</h2>"
        }
        
        return "<h2>Section \(sectionIndex + 1)</h2>"
    }
    
    private static func generateRemainingFields(
        count: Int,
        startIndex: Int,
        configuration: TestConfiguration
    ) -> [FormField] {
        return (0..<count).map { index in
            generateField(
                index: startIndex + index,
                sectionIndex: -1, // No section
                configuration: configuration
            )
        }
    }
    
    private static func benchmarkConfiguration(_ config: TestConfiguration) -> VirtualScrollingBenchmarkResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let form = generateInfiniteFieldsForm(configuration: config)
        
        let generationTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Test virtual items generation
        let virtualStartTime = CFAbsoluteTimeGetCurrent()
        
        let virtualItems = VirtualFormItemGenerator.generateVirtualItems(
            form: form,
            editContext: .newEntry,
            successMessage: nil,
            isAutoSaveEnabled: true,
            lastAutoSaveTime: nil,
            fieldValues: [:]
        )
        
        let virtualGenerationTime = CFAbsoluteTimeGetCurrent() - virtualStartTime
        
        return VirtualScrollingBenchmarkResult(
            fieldCount: config.fieldCount,
            sectionCount: config.sectionCount,
            formGenerationTime: generationTime,
            virtualItemsGenerationTime: virtualGenerationTime,
            virtualItemsCount: virtualItems.count,
            memoryUsageApprox: estimateMemoryUsage(form: form, virtualItems: virtualItems)
        )
    }
    
    private static func estimateMemoryUsage(form: DynamicForm, virtualItems: [VirtualFormItem]) -> Int {
        // Rough estimation in bytes
        let fieldMemory = form.fields.count * 200 // ~200 bytes per field
        let sectionMemory = form.sections.count * 100 // ~100 bytes per section
        let virtualItemMemory = virtualItems.count * 50 // ~50 bytes per virtual item
        
        return fieldMemory + sectionMemory + virtualItemMemory
    }
}

// MARK: - Benchmark Results
public struct VirtualScrollingBenchmarkResult {
    public let fieldCount: Int
    public let sectionCount: Int
    public let formGenerationTime: TimeInterval
    public let virtualItemsGenerationTime: TimeInterval
    public let virtualItemsCount: Int
    public let memoryUsageApprox: Int
    
    public var isPerformant: Bool {
        // Performance criteria: virtual items generation should be under 16ms for 60fps
        return virtualItemsGenerationTime < 0.016
    }
    
    public var debugDescription: String {
        return """
        Benchmark Result (Fields: \(fieldCount)):
        - Form Generation: \(String(format: "%.2fms", formGenerationTime * 1000))
        - Virtual Items Generation: \(String(format: "%.2fms", virtualItemsGenerationTime * 1000))
        - Virtual Items Count: \(virtualItemsCount)
        - Estimated Memory: \(memoryUsageApprox / 1024)KB
        - Performance: \(isPerformant ? "✅ GOOD" : "⚠️ NEEDS OPTIMIZATION")
        """
    }
}

public struct VirtualScrollingBenchmarkResults {
    public let results: [VirtualScrollingBenchmarkResult]
    
    public var overallPerformance: String {
        let performantCount = results.filter { $0.isPerformant }.count
        let totalCount = results.count
        
        return "\(performantCount)/\(totalCount) tests passed performance criteria"
    }
    
    public var debugDescription: String {
        var description = "Virtual Scrolling Benchmark Results:\n"
        description += "Overall Performance: \(overallPerformance)\n\n"
        
        for result in results {
            description += result.debugDescription + "\n\n"
        }
        
        return description
    }
}
