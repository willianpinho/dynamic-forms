import SwiftUI
import Domain
import DesignSystem
import UIComponents
import Combine

/// Form detail view using SwiftUI and MVVM pattern
/// Provides form filling interface with sections, validation, and auto-save
public struct FormDetailView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel: FormDetailViewModel
    private let onSaved: (FormEntry) -> Void
    private let onSubmitted: (FormEntry) -> Void
    private let onCancel: () -> Void
    
    // MARK: - State
    @State private var showingCancelAlert = false
    @State private var showingSaveAlert = false
    
    // MARK: - Initialization
    public init(
        viewModel: FormDetailViewModel,
        onSaved: @escaping (FormEntry) -> Void,
        onSubmitted: @escaping (FormEntry) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onSaved = onSaved
        self.onSubmitted = onSubmitted
        self.onCancel = onCancel
    }
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                progressSection
                contentView
                bottomToolbar
            }
            .navigationTitle(viewModel.form.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    autoSaveIndicator
                }
            }
        }
        .onAppear {
            viewModel.loadForm()
        }
        .alert("Cancel Editing", isPresented: $showingCancelAlert) {
            Button("Keep Editing", role: .cancel) {}
            Button("Discard Changes", role: .destructive) {
                onCancel()
            }
        } message: {
            Text("Are you sure you want to discard your changes?")
        }
        .alert("Save Draft", isPresented: $showingSaveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Save Draft") {
                viewModel.saveDraft()
            }
        } message: {
            Text("Save your progress as a draft?")
        }
        .onChange(of: viewModel.uiState) { state in
            handleStateChange(state)
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: DFSpacing.sm) {
            // Overall progress
            HStack {
                Text("Progress")
                    .font(DFTypography.labelMedium)
                    .foregroundColor(DFColors.onSurface)
                
                Spacer()
                
                Text("\(Int(viewModel.completionPercentage * 100))%")
                    .font(DFTypography.labelMedium)
                    .foregroundColor(DFColors.primary)
            }
            
            ProgressView(value: viewModel.completionPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: DFColors.primary))
                .frame(height: 4)
        }
        .padding(.horizontal, DFSpacing.Layout.screenPadding)
        .padding(.vertical, DFSpacing.sm)
        .background(DFColors.surface)
        .shadow(color: DFColors.shadow.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    

    
    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.uiState {
        case .loading:
            LoadingView(message: "Loading form...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        case .loaded:
            formContent
            
        case .saving:
            LoadingView(message: "Saving...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        case .submitted:
            // No local submitted view - navigation handled by coordinator
            formContent
            
        case .error(let errorMessage):
            ErrorView(
                title: "Error",
                message: errorMessage,
                style: .fullscreen,
                retryAction: viewModel.clearErrorAndReturnToForm
            )
        }
    }
    
    // MARK: - Form Content (O(1) Virtual Scrolling)
    private var formContent: some View {
        ScrollView {
            LazyVStack(spacing: DFSpacing.sm) {
                // Virtual scrolling for O(1) performance
                ForEach(viewModel.virtualItems) { item in
                    VirtualFormItemView(
                        item: item,
                        fieldValues: viewModel.fieldValues,
                        validationErrors: viewModel.validationErrors,
                        onFieldValueChange: { fieldUuid, value in
                            viewModel.updateFieldValue(fieldUuid: fieldUuid, value: value)
                        },
                        onSaveDraft: {
                            viewModel.saveDraft()
                        },
                        onSubmitForm: {
                            viewModel.submitForm()
                        },
                        onClearSuccessMessage: {
                            viewModel.clearSuccessMessage()
                        }
                    )
                }
            }
            .padding(.horizontal, DFSpacing.Layout.screenPadding)
            .padding(.vertical, DFSpacing.md)
        }
    }
    
    // MARK: - Legacy Content Views (Kept for fallback)
    // These are kept as fallback in case virtual scrolling has issues
    // but the main content now uses O(1) virtual scrolling
    

    
    // MARK: - Bottom Toolbar
    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: DFSpacing.md) {
                // Save draft button
                SecondaryButton(title: "Save Draft") {
                    viewModel.saveDraft()
                }
                
                // Submit button
                PrimaryButton(
                    title: "Submit",
                    isEnabled: viewModel.canSubmit,
                    isLoading: viewModel.uiState.isSaving
                ) {
                    viewModel.submitForm()
                }
            }
            .padding(.horizontal, DFSpacing.Layout.screenPadding)
            .padding(.vertical, DFSpacing.md)
        }
        .background(DFColors.surface)
    }
    
    // MARK: - Toolbar Items
    private var cancelButton: some View {
        Button("Cancel") {
            showingCancelAlert = true
        }
    }
    
    private var autoSaveIndicator: some View {
        HStack(spacing: DFSpacing.xs) {
            if viewModel.isAutoSaving {
                ProgressView()
                    .scaleEffect(0.7)
                
                Text("Saving...")
                    .font(DFTypography.labelSmall)
                    .foregroundColor(DFColors.onSurfaceVariant)
            } else if let lastSaved = viewModel.lastSavedAt {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DFColors.success)
                    .font(.system(size: 12))
                
                Text("Saved")
                    .font(DFTypography.labelSmall)
                    .foregroundColor(DFColors.onSurfaceVariant)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleStateChange(_ state: FormDetailUiState) {
        switch state {
        case .submitted:
            // Navigate immediately after submission, no delay
            onSubmitted(viewModel.entry)
        default:
            break
        }
    }
}



// MARK: - Previews
#if DEBUG
// Preview temporarily disabled due to build issues
#endif
