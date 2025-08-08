import SwiftUI
import Domain
import DesignSystem
import UIComponents

/// Form entries view using SwiftUI and MVVM pattern
/// Displays entries for a specific form with filtering and management
public struct FormEntriesView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel: FormEntriesViewModel
    private let onCreateNew: () -> Void
    private let onEditEntry: (FormEntry) -> Void
    private let onCreateEditDraft: (FormEntry) -> Void
    
    // MARK: - State
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: FormEntry?
    @State private var showingBulkDeleteAlert = false
    @State private var showingStatistics = false
    @State private var selectedEntries = Set<String>()
    @State private var showingBulkActions = false
    
    // MARK: - Initialization
    public init(
        viewModel: FormEntriesViewModel,
        onCreateNew: @escaping () -> Void,
        onEditEntry: @escaping (FormEntry) -> Void,
        onCreateEditDraft: @escaping (FormEntry) -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onCreateNew = onCreateNew
        self.onEditEntry = onEditEntry
        self.onCreateEditDraft = onCreateEditDraft
    }
    
    // MARK: - Body
    public var body: some View {
        VStack(spacing: 0) {
            searchAndFilterSection
            contentView
        }
        .navigationTitle("Form Entries")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarItems(
            trailing: HStack(spacing: DFSpacing.sm) {
                // Add New Entry Button
                Button {
                    onCreateNew()
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(DFColors.primary)
                        .font(.title2)
                }
                
                // Statistics Button
                Button {
                    showingStatistics = true
                } label: {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .foregroundColor(DFColors.primary)
                }
            }
        )
        .onAppear {
            viewModel.loadEntries()
        }
        .alert("Delete Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let entry = entryToDelete {
                    viewModel.deleteEntry(entry)
                }
                entryToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this entry? This action cannot be undone.")
        }
        .alert("Delete Selected Entries", isPresented: $showingBulkDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete All", role: .destructive) {
                viewModel.bulkDeleteSelectedEntries()
            }
        } message: {
            Text("Are you sure you want to delete \(viewModel.selectedEntries.count) selected entries? This action cannot be undone.")
        }
        .sheet(isPresented: $viewModel.showingSortOptions) {
            SortOptionsView(
                selectedSortOption: $viewModel.selectedSortOption,
                onDismiss: viewModel.hideSortOptions
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingStatistics) {
            EntryStatisticsDetailView(
                statistics: viewModel.getEntryStatistics(),
                formTitle: viewModel.formTitle
            )
            .presentationDetents([.medium, .large])
        }
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: DFSpacing.sm) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DFColors.onSurfaceVariant)
                
                TextField("Search by name, content, ID, status, or date...", text: $viewModel.searchText)
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
            
            // Filter and sort options
            HStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DFSpacing.sm) {
                        ForEach(EntryFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                filter: filter,
                                isSelected: viewModel.selectedFilter == filter
                            ) {
                                viewModel.updateFilter(filter)
                            }
                        }
                    }
                    .padding(.horizontal, DFSpacing.Layout.screenPadding)
                }
                
                // Sort button
                SortButton(
                    currentSort: viewModel.selectedSortOption,
                    onTap: viewModel.showSortOptions
                )
                .padding(.trailing, DFSpacing.Layout.screenPadding)
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
            LoadingView(message: "Loading entries...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        case .loaded(let entries):
            VStack(spacing: 0) {
                // Search results header (if searching)
                if !viewModel.searchText.isEmpty {
                    searchResultsHeader(count: entries.count)
                }
                
                // Entries list
                entriesList(entries)
                
                // Bulk actions toolbar
                BulkActionsView(
                    selectedEntries: $viewModel.selectedEntries,
                    allEntries: entries,
                    isSelectionMode: viewModel.isSelectionMode,
                    onToggleSelectionMode: viewModel.toggleSelectionMode,
                    onSelectAll: viewModel.selectAllEntries,
                    onDeselectAll: viewModel.deselectAllEntries,
                    onBulkDelete: { _ in
                        showingBulkDeleteAlert = true
                    },
                    onBulkExport: { _ in
                        viewModel.bulkExportEntries()
                    }
                )
            }
            
        case .empty:
            EmptyStateView(
                title: "No Entries Found",
                message: getEmptyStateMessage(),
                iconName: getEmptyStateIcon(),
                actionTitle: "Create New Entry",
                action: onCreateNew
            )
            
        case .error(let errorMessage):
            ErrorView(
                title: "Error Loading Entries",
                message: errorMessage,
                style: .fullscreen,
                retryAction: viewModel.retryLoading
            )
        }
    }
    

    
    // MARK: - Entries List
    private func entriesList(_ entries: [FormEntry]) -> some View {
        ScrollView {
            LazyVStack(spacing: DFSpacing.Layout.cardSpacing) {
                ForEach(entries, id: \.id) { entry in
                    EntryCardView(
                        entry: entry,
                        isSelectionMode: viewModel.isSelectionMode,
                        isSelected: viewModel.selectedEntries.contains(entry.id),
                        onTap: { 
                            if viewModel.isSelectionMode {
                                viewModel.toggleEntrySelection(entry.id)
                            } else {
                                onEditEntry(entry)
                            }
                        },
                        onEdit: { onEditEntry(entry) },
                        onCreateEditDraft: (entry.status == .submitted || entry.status == .completed) ? { onCreateEditDraft(entry) } : nil,
                        onDelete: {
                            entryToDelete = entry
                            showingDeleteAlert = true
                        },
                        onToggleSelection: {
                            viewModel.toggleEntrySelection(entry.id)
                        }
                    )
                }
            }
            .padding(.horizontal, DFSpacing.Layout.screenPadding)
            .padding(.vertical, DFSpacing.sm)
        }
        .refreshable {
            viewModel.refreshEntries()
        }
    }
    

    
    // MARK: - Search Results Header
    private func searchResultsHeader(count: Int) -> some View {
        HStack {
            Text("\(count) result\(count == 1 ? "" : "s") for '\(viewModel.searchText)'")
                .font(DFTypography.labelMedium)
                .foregroundColor(DFColors.onSurfaceVariant)
            
            Spacer()
            
            Button("Clear") {
                viewModel.clearSearch()
            }
            .font(DFTypography.labelMedium)
            .foregroundColor(DFColors.primary)
        }
        .padding(.horizontal, DFSpacing.Layout.screenPadding)
        .padding(.vertical, DFSpacing.xs)
        .background(DFColors.surfaceVariant.opacity(0.5))
    }
    
    // MARK: - Helper Methods
    private func getEmptyStateMessage() -> String {
        if !viewModel.searchText.isEmpty {
            return "No entries match your search criteria."
        }
        
        switch viewModel.selectedFilter {
        case .all:
            return "No entries have been created for this form yet. Tap 'Create New Entry' to get started."
        case .drafts:
            return "No draft entries found."
        case .completed:
            return "No completed entries found."
        case .editDrafts:
            return "No edit drafts found."
        }
    }
    
    private func getEmptyStateIcon() -> String {
        switch viewModel.selectedFilter {
        case .all:
            return "doc.text"
        case .drafts:
            return "doc.text.fill"
        case .completed:
            return "checkmark.circle"
        case .editDrafts:
            return "pencil.circle"
        }
    }
}

// MARK: - Filter Chip
private struct FilterChip: View {
    let filter: EntryFilter
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DFSpacing.xs) {
                Image(systemName: filter.iconName)
                    .font(.system(size: 12))
                
                Text(filter.displayName)
                    .font(DFTypography.labelSmall)
            }
            .padding(.horizontal, DFSpacing.sm)
            .padding(.vertical, DFSpacing.xs)
            .background(isSelected ? DFColors.primary : DFColors.surfaceVariant)
            .foregroundColor(isSelected ? DFColors.onPrimary : DFColors.onSurfaceVariant)
            .cornerRadius(DesignSystem.BorderRadius.large)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Entry Card View
private struct EntryCardView: View {
    let entry: FormEntry
    let isSelectionMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onCreateEditDraft: (() -> Void)?
    let onDelete: () -> Void
    let onToggleSelection: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DFSpacing.sm) {
            // Header
            HStack {
                // Selection checkbox (if in selection mode)
                if isSelectionMode {
                    SelectionCheckbox(
                        isSelected: isSelected,
                        onToggle: onToggleSelection
                    )
                }
                
                VStack(alignment: .leading, spacing: DFSpacing.xs) {
                    HStack {
                        StatusBadge(status: entry.status)
                        Spacer()
                        Text(entry.updatedAt, style: .date)
                            .font(DFTypography.labelSmall)
                            .foregroundColor(DFColors.onSurfaceVariant)
                    }
                    
                    // Main entry title
                    Text(entry.generateDisplayTitle())
                        .font(DFTypography.labelMedium)
                        .foregroundColor(DFColors.onSurface)
                        .lineLimit(1)
                    
                    // Subtitle with additional context
                    Text(entry.generateDisplaySubtitle())
                        .font(DFTypography.labelSmall)
                        .foregroundColor(DFColors.onSurfaceVariant)
                }
                
                Menu {
                    Button(action: onEdit) {
                        // Different label based on entry status
                        switch entry.status {
                        case .draft, .editDraft:
                            Label("Continue Editing", systemImage: "pencil")
                        case .submitted, .completed:
                            Label("View Details", systemImage: "eye")
                        }
                    }
                    
                    if let onCreateEditDraft = onCreateEditDraft {
                        Button(action: onCreateEditDraft) {
                            Label("Create Edit Draft", systemImage: "doc.on.doc")
                        }
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(DFColors.onSurfaceVariant)
                }
            }
            
            // Content preview
            if entry.hasData {
                VStack(alignment: .leading, spacing: DFSpacing.xs) {
                    Text("Field Values:")
                        .font(DFTypography.labelMedium)
                        .foregroundColor(DFColors.onSurface)
                    
                    let nonEmptyValues = entry.getNonEmptyFieldValues()
                    ForEach(Array(nonEmptyValues.prefix(3)), id: \.key) { key, value in
                        HStack {
                            Text(key)
                                .font(DFTypography.labelSmall)
                                .foregroundColor(DFColors.onSurfaceVariant)
                            
                            Spacer()
                            
                            Text(value)
                                .font(DFTypography.labelSmall)
                                .foregroundColor(DFColors.onSurface)
                                .lineLimit(1)
                        }
                    }
                    
                    if nonEmptyValues.count > 3 {
                        Text("+ \(nonEmptyValues.count - 3) more fields")
                            .font(DFTypography.labelSmall)
                            .foregroundColor(DFColors.onSurfaceVariant)
                    }
                }
            }
        }
        .padding(DFSpacing.Layout.cardPadding)
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
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Status Badge
private struct StatusBadge: View {
    let status: EntryStatus
    
    var body: some View {
        HStack(spacing: DFSpacing.xs) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(status.displayName)
                .font(DFTypography.labelSmall)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, DFSpacing.xs)
        .padding(.vertical, 2)
        .background(statusColor.opacity(0.1))
        .cornerRadius(DesignSystem.BorderRadius.small)
    }
    
    private var statusColor: Color {
        switch status {
        case .draft, .editDraft:
            return DFColors.warning
        case .submitted, .completed:
            return DFColors.success
        }
    }
}

// MARK: - Previews
#if DEBUG
struct FormEntriesView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Form Entries Preview")
            .previewDisplayName("Form Entries")
    }
}
#endif
