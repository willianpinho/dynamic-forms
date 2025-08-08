import SwiftUI
import Domain
import DesignSystem
import UIComponents

/// Form list view using SwiftUI and MVVM pattern
/// Displays available forms with search and sort functionality
public struct FormListView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel: FormListViewModel
    private let onFormSelected: (DynamicForm) -> Void
    
    // MARK: - Initialization
    public init(
        viewModel: FormListViewModel,
        onFormSelected: @escaping (DynamicForm) -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onFormSelected = onFormSelected
    }
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchAndSortSection
                contentView
            }
            .navigationTitle("DynamicForms")
            .navigationBarTitleDisplayMode(.large)

        }
        .onAppear {
            viewModel.loadForms()
        }
    }
    
    // MARK: - Search and Sort Section
    private var searchAndSortSection: some View {
        VStack(spacing: DFSpacing.sm) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DFColors.onSurfaceVariant)
                
                TextField("Search forms...", text: $viewModel.searchText)
                    .font(DFTypography.bodyMedium)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !viewModel.searchText.isEmpty {
                    Button(action: viewModel.clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DFColors.onSurfaceVariant)
                    }
                }
            }
            .padding(DFSpacing.sm)
            .background(DFColors.surfaceVariant.opacity(0.3))
            .cornerRadius(DesignSystem.BorderRadius.small)
            
            // Sort options
            HStack {
                Text("Sort by:")
                    .font(DFTypography.labelMedium)
                    .foregroundColor(DFColors.onSurfaceVariant)
                
                Picker("Sort", selection: $viewModel.sortOption) {
                    ForEach(FormSortOption.allCases, id: \.self) { option in
                        Text(option.displayName)
                            .tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .font(DFTypography.labelMedium)
                .onChange(of: viewModel.sortOption) { newValue in
                    print("🔄 Sort option changed to: \(newValue.displayName)")
                    viewModel.refreshForms()
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, DFSpacing.Layout.screenPadding)
        .padding(.vertical, DFSpacing.sm)
    }
    
    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.uiState {
        case .loading:
            LoadingView(message: "Loading forms...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        case .loaded(let forms):
            formsList(forms)
            
        case .empty:
            let message = viewModel.searchText.isEmpty 
                ? "No forms are available at the moment."
                : "No forms match your search criteria."
            let actionTitle = viewModel.searchText.isEmpty ? nil : "Clear Search"
            let action = viewModel.searchText.isEmpty ? nil : viewModel.clearSearch
            
            EmptyStateView(
                title: "No Forms Found",
                message: message,
                iconName: "doc.text",
                actionTitle: actionTitle,
                action: action
            )
            
        case .error(let errorMessage):
            ErrorView(
                title: "Error Loading Forms",
                message: errorMessage,
                style: .fullscreen,
                retryAction: viewModel.retryLoading
            )
        }
    }
    
    // MARK: - Forms List
    private func formsList(_ forms: [DynamicForm]) -> some View {
        ScrollView {
            LazyVStack(spacing: DFSpacing.Layout.cardSpacing) {
                ForEach(forms, id: \.id) { form in
                    FormCardView(form: form) {
                        onFormSelected(form)
                    }
                }
            }
            .padding(.horizontal, DFSpacing.Layout.screenPadding)
            .padding(.vertical, DFSpacing.sm)
        }
        .refreshable {
            viewModel.refreshForms()
        }
    }
    

}

// MARK: - Form Card View
private struct FormCardView: View {
    let form: DynamicForm
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: DFSpacing.sm) {
                // Header
                HStack {
                    Text(form.title)
                        .font(DFTypography.titleMedium)
                        .foregroundColor(DFColors.onSurface)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DFColors.onSurfaceVariant)
                }
                
                // Metadata
                VStack(alignment: .leading, spacing: DFSpacing.xs) {
                    HStack {
                        Label("\(form.fields.count) fields", systemImage: "list.bullet")
                        
                        if !form.sections.isEmpty {
                            Label("\(form.sections.count) sections", systemImage: "rectangle.stack")
                        }
                    }
                    .font(DFTypography.labelSmall)
                    .foregroundColor(DFColors.onSurfaceVariant)
                    
                    Text("Created \(form.createdAt, style: .date)")
                        .font(DFTypography.labelSmall)
                        .foregroundColor(DFColors.onSurfaceVariant)
                }
                
                // Progress bar for required fields
                if form.getRequiredFields().count > 0 {
                    HStack {
                        Text("Required fields: \(form.getRequiredFields().count)")
                            .font(DFTypography.labelSmall)
                            .foregroundColor(DFColors.onSurfaceVariant)
                        
                        Spacer()
                    }
                }
            }
            .padding(DFSpacing.Layout.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DFColors.surface)
            .cornerRadius(DesignSystem.BorderRadius.medium)
            .shadow(
                color: DFColors.shadow.opacity(0.1),
                radius: DesignSystem.Elevation.low,
                x: 0,
                y: 2
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                    .stroke(DFColors.outline.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews
#if DEBUG
struct FormListView_Previews: PreviewProvider {
    static var previews: some View {
        FormListView(
            viewModel: FormListViewModel(
                getAllFormsUseCase: GetAllFormsUseCase(formRepository: MockFormRepository()),
                initializeFormsUseCase: InitializeFormsUseCase(formRepository: MockFormRepository()),
                formRepository: MockFormRepository()
            ),
            onFormSelected: { _ in }
        )
        .previewDisplayName("Form List")
    }
}
#endif
