import Foundation
import Combine

/// Test use case to verify form loading functionality
/// This is a temporary debug utility to check if forms are loading correctly
@available(iOS 13.0, macOS 10.15, *)
public final class TestFormLoadingUseCase {
    
    // MARK: - Dependencies
    private let formRepository: FormRepository
    
    // MARK: - Initialization
    public init(formRepository: FormRepository) {
        self.formRepository = formRepository
    }
    
    // MARK: - Test Methods
    
    /// Test if forms can be loaded from assets
    public func testAssetLoading() async -> TestResult {
        do {
            let result = await formRepository.loadFormsFromAssets()
            
            switch result {
            case .success(let forms):
                var details: [String] = []
                details.append("✅ Successfully loaded \(forms.count) forms:")
                
                for (index, form) in forms.enumerated() {
                    details.append("  \(index + 1). \(form.title)")
                    details.append("     ID: \(form.id)")
                    details.append("     Fields: \(form.fields.count)")
                    details.append("     Sections: \(form.sections.count)")
                }
                
                return TestResult.success(details.joined(separator: "\n"))
                
            case .failure(let error):
                return TestResult.failure("❌ Failed to load forms: \(error.localizedDescription)")
            }
            
        } catch {
            return TestResult.failure("❌ Error during asset loading test: \(error.localizedDescription)")
        }
    }
    
    /// Test if forms are properly initialized in repository
    public func testFormInitialization() async -> TestResult {
        do {
            let isInitialized = await formRepository.isFormsDataInitialized()
            
            if isInitialized {
                // Get forms from repository
                let forms = try await formRepository.getAllForms()
                
                var details: [String] = []
                details.append("✅ Forms are initialized in repository")
                details.append("✅ Found \(forms.count) forms in repository:")
                
                for (index, form) in forms.enumerated() {
                    details.append("  \(index + 1). \(form.title) (ID: \(form.id))")
                }
                
                return TestResult.success(details.joined(separator: "\n"))
                
            } else {
                return TestResult.failure("❌ Forms are not initialized in repository")
            }
            
        } catch {
            return TestResult.failure("❌ Error during initialization test: \(error.localizedDescription)")
        }
    }
    
    /// Test complete form loading flow
    public func testCompleteFlow() async -> TestResult {
        var results: [String] = []
        
        // Test 1: Asset loading
        let assetResult = await testAssetLoading()
        switch assetResult {
        case .success(let message):
            results.append("ASSET LOADING TEST:")
            results.append(message)
        case .failure(let error):
            results.append("ASSET LOADING TEST:")
            results.append(error)
            return TestResult.failure(results.joined(separator: "\n"))
        }
        
        results.append("\n" + String(repeating: "-", count: 50) + "\n")
        
        // Test 2: Initialization
        let initResult = await testFormInitialization()
        switch initResult {
        case .success(let message):
            results.append("INITIALIZATION TEST:")
            results.append(message)
        case .failure(let error):
            results.append("INITIALIZATION TEST:")
            results.append(error)
            return TestResult.failure(results.joined(separator: "\n"))
        }
        
        return TestResult.success(results.joined(separator: "\n"))
    }
    
    /// Test specific form by ID
    public func testFormById(_ formId: String) async -> TestResult {
        do {
            let form = try await withCheckedThrowingContinuation { continuation in
                let cancellable = formRepository.getFormById(formId)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { form in
                            continuation.resume(returning: form)
                        }
                    )
                _ = cancellable
            }
            
            if let form = form {
                var details: [String] = []
                details.append("✅ Found form: \(form.title)")
                details.append("   ID: \(form.id)")
                details.append("   Fields: \(form.fields.count)")
                details.append("   Sections: \(form.sections.count)")
                details.append("   Created: \(form.createdAt)")
                
                // Test field details
                if !form.fields.isEmpty {
                    details.append("   Sample fields:")
                    for field in form.fields.prefix(3) {
                        details.append("     - \(field.label) (\(field.type.rawValue))")
                    }
                    if form.fields.count > 3 {
                        details.append("     ... and \(form.fields.count - 3) more")
                    }
                }
                
                return TestResult.success(details.joined(separator: "\n"))
                
            } else {
                return TestResult.failure("❌ Form with ID '\(formId)' not found")
            }
            
        } catch {
            return TestResult.failure("❌ Error testing form by ID: \(error.localizedDescription)")
        }
    }
}

// MARK: - Test Result
public enum TestResult {
    case success(String)
    case failure(String)
    
    public var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    public var message: String {
        switch self {
        case .success(let message), .failure(let message):
            return message
        }
    }
}

// Publisher async extension is now provided in the global Publisher+Async.swift file
