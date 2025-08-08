import SwiftUI
import Combine
import Domain
import FormListFeature
import FormEntriesFeature
import FormDetailFeature
import DesignSystem
import Foundation

/// Main app coordinator managing navigation between features
/// Following Coordinator Pattern for centralized navigation logic
@MainActor
public final class AppCoordinator: ObservableObject, View {
    
    // MARK: - View Body
    public var body: some View {
        NavigationStack(path: Binding(get: { self.navigationPath }, set: { self.navigationPath = $0 })) {
            FormListView(
                viewModel: FormListViewModel(
                    getAllFormsUseCase: DIContainer.shared.getGetAllFormsUseCase(),
                    initializeFormsUseCase: DIContainer.shared.getInitializeFormsUseCase(),
                    formRepository: DIContainer.shared.getFormRepository()
                ),
                onFormSelected: { form in
                    self.showFormEntries(for: form)
                }
            )
            .navigationDestination(for: Screen.self) { screen in
                switch screen {
                case .formList:
                    FormListView(
                        viewModel: FormListViewModel(
                            getAllFormsUseCase: DIContainer.shared.getGetAllFormsUseCase(),
                            initializeFormsUseCase: DIContainer.shared.getInitializeFormsUseCase(),
                            formRepository: DIContainer.shared.getFormRepository()
                        ),
                        onFormSelected: { form in
                            self.showFormEntries(for: form)
                        }
                    )
                    
                case .formEntries(let form):
                    FormEntriesView(
                        viewModel: FormEntriesViewModel(
                            form: form,
                            getFormEntriesUseCase: DIContainer.shared.getGetFormEntriesUseCase(),
                            deleteFormEntryUseCase: DIContainer.shared.getDeleteFormEntryUseCase()
                        ),
                        onCreateNew: {
                            self.createNewEntry(for: form)
                        },
                        onEditEntry: { entry in
                            self.editEntry(entry, form: form)
                        },
                        onCreateEditDraft: { entry in
                            self.createEditDraft(from: entry, form: form)
                        }
                    )
                    
                case .formDetail(let form, let entry):
                    FormDetailView(
                        viewModel: FormDetailViewModel(
                            form: form,
                            entry: entry,
                            saveFormEntryUseCase: DIContainer.shared.getSaveFormEntryUseCase(),
                            validateFormEntryUseCase: DIContainer.shared.getValidateFormEntryUseCase(),
                            autoSaveFormEntryUseCase: AutoSaveFormEntryUseCaseAdapter(
                                domainUseCase: DIContainer.shared.getAutoSaveFormEntryUseCase()
                            )
                        ),
                        onSaved: { savedEntry in
                            self.handleDraftSaved(savedEntry)
                        },
                        onSubmitted: { submittedEntry in
                            self.handleFormSubmission(submittedEntry)
                        },
                        onCancel: {
                            self.goBack()
                        }
                    )
                    
                case .formSubmitted(let entry):
                    FormSubmittedView(entry: entry) {
                        self.goToFormEntries()
                    }
                }
            }
        }
        .environmentObject(self)
    }
    
    // MARK: - Published Properties
    @Published public var currentScreen: Screen = .formList
    @Published public var navigationPath = NavigationPath()
    
    // MARK: - Dependencies
    private let diContainer: DIContainer
    
    // MARK: - Navigation State
    private var selectedForm: DynamicForm?
    private var selectedEntry: FormEntry?
    
    // MARK: - Screen Definitions
    public enum Screen: Hashable {
        case formList
        case formEntries(DynamicForm)
        case formDetail(DynamicForm, FormEntry?)
        case formSubmitted(FormEntry)
    }
    
    // MARK: - Initialization
    public init(diContainer: DIContainer = DIContainer.shared) {
        self.diContainer = diContainer
    }
    
    // MARK: - Navigation Methods
    
    /// Navigate to form entries for a specific form
    public func showFormEntries(for form: DynamicForm) {
        selectedForm = form
        currentScreen = .formEntries(form)
        navigationPath.append(currentScreen)
    }
    
    /// Navigate to form detail for filling/editing
    public func showFormDetail(form: DynamicForm, entry: FormEntry? = nil) {
        selectedForm = form
        selectedEntry = entry
        currentScreen = .formDetail(form, entry)
        navigationPath.append(currentScreen)
    }
    
    /// Navigate to new form entry
    public func createNewEntry(for form: DynamicForm) {
        let newEntry = FormEntry.newDraft(formId: form.id)
        showFormDetail(form: form, entry: newEntry)
    }
    
    /// Navigate to edit existing entry
    public func editEntry(_ entry: FormEntry, form: DynamicForm) {
        showFormDetail(form: form, entry: entry)
    }
    
    /// Create edit draft from completed entry
    public func createEditDraft(from entry: FormEntry, form: DynamicForm) {
        let editDraft = entry.createEditDraft()
        showFormDetail(form: form, entry: editDraft)
    }
    
    /// Navigate back to previous screen
    public func goBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
            updateCurrentScreen()
        }
    }
    
    /// Navigate back to form list
    public func goToFormList() {
        navigationPath = NavigationPath()
        currentScreen = .formList
        selectedForm = nil
        selectedEntry = nil
    }
    
    /// Navigate back to form entries
    public func goToFormEntries() {
        guard let form = selectedForm else { return }
        
        // Remove detail screens and go back to entries
        while !navigationPath.isEmpty && currentScreen != .formEntries(form) {
            navigationPath.removeLast()
        }
        
        currentScreen = .formEntries(form)
    }
    
    /// Handle draft saved
    public func handleDraftSaved(_ entry: FormEntry) {
        // Navigate back to form entries
        goToFormEntries()
    }
    
    /// Handle form submission
    public func handleFormSubmission(_ entry: FormEntry) {
        // Navigate to submission confirmation
        currentScreen = .formSubmitted(entry)
        navigationPath.append(currentScreen)
    }
    
    /// Update current screen based on navigation path
    private func updateCurrentScreen() {
        // NavigationPath doesn't expose a direct last property
        // We need to track the current screen separately or use a different approach
        // For now, we'll keep the current screen as is when going back
        // The NavigationStack will handle the actual navigation state
    }
}

// MARK: - AutoSaveFormEntryUseCase Adapter
/// Adapter to bridge Domain.AutoSaveFormEntryUseCase to FormDetailFeature.FormDetailAutoSaveUseCase
/// This follows the Adapter pattern to resolve circular dependencies
private class AutoSaveFormEntryUseCaseAdapter: FormDetailAutoSaveUseCase {
    private let domainUseCase: AutoSaveFormEntryUseCaseProtocol
    
    init(domainUseCase: AutoSaveFormEntryUseCaseProtocol) {
        self.domainUseCase = domainUseCase
    }
    
    func execute(entry: FormEntry) async -> Result<Void, Error> {
        return await domainUseCase.execute(entry: entry)
    }
}

// MARK: - Form Submitted View
private struct FormSubmittedView: View {
    let entry: FormEntry
    let onDone: () -> Void
    
    var body: some View {
        VStack(spacing: DFSpacing.xl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(DFColors.success)
            
            VStack(spacing: DFSpacing.md) {
                Text("Form Submitted!")
                    .font(DFTypography.headlineMedium)
                    .foregroundColor(DFColors.onSurface)
                
                Text("Your form has been successfully submitted.")
                    .font(DFTypography.bodyLarge)
                    .foregroundColor(DFColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                
                Text("Entry ID: \(entry.id.prefix(8))")
                    .font(DFTypography.labelMedium)
                    .foregroundColor(DFColors.onSurfaceVariant)
            }
            
            PrimaryButton(title: "Done") {
                onDone()
            }
            .padding(.horizontal, DFSpacing.xl)
        }
        .padding(DFSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DFColors.background)
        .navigationBarBackButtonHidden()
    }
}
