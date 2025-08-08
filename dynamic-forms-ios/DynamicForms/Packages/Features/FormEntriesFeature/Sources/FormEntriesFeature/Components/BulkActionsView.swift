import SwiftUI
import Domain
import DesignSystem

/// Bulk actions view for managing multiple entries
/// Provides selection mode and batch operations
public struct BulkActionsView: View {
    
    // MARK: - Properties
    @Binding var selectedEntries: Set<String>
    let allEntries: [FormEntry]
    let isSelectionMode: Bool
    let onToggleSelectionMode: () -> Void
    let onSelectAll: () -> Void
    let onDeselectAll: () -> Void
    let onBulkDelete: ([FormEntry]) -> Void
    let onBulkExport: ([FormEntry]) -> Void
    
    // MARK: - Computed Properties
    private var selectedEntriesArray: [FormEntry] {
        return allEntries.filter { selectedEntries.contains($0.id) }
    }
    
    private var canDelete: Bool {
        return !selectedEntries.isEmpty
    }
    
    private var canExport: Bool {
        return !selectedEntries.isEmpty
    }
    
    // MARK: - Body
    public var body: some View {
        if isSelectionMode {
            selectionModeToolbar
        } else {
            normalModeToolbar
        }
    }
    
    // MARK: - Selection Mode Toolbar
    private var selectionModeToolbar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(DFColors.outline.opacity(0.2))
            
            HStack(spacing: DFSpacing.md) {
                // Selection info
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(selectedEntries.count) selected")
                        .font(DFTypography.labelMedium)
                        .foregroundColor(DFColors.onSurface)
                    
                    if selectedEntries.count > 0 {
                        Text("of \(allEntries.count) entries")
                            .font(DFTypography.labelSmall)
                            .foregroundColor(DFColors.onSurfaceVariant)
                    }
                }
                
                Spacer()
                
                // Selection actions
                HStack(spacing: DFSpacing.sm) {
                    if selectedEntries.count < allEntries.count {
                        Button("Select All") {
                            onSelectAll()
                        }
                        .font(DFTypography.labelMedium)
                        .foregroundColor(DFColors.primary)
                    }
                    
                    if !selectedEntries.isEmpty {
                        Button("Deselect") {
                            onDeselectAll()
                        }
                        .font(DFTypography.labelMedium)
                        .foregroundColor(DFColors.primary)
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: DFSpacing.sm) {
                    // Export button
                    Button(action: {
                        onBulkExport(selectedEntriesArray)
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                    }
                    .disabled(!canExport)
                    .foregroundColor(canExport ? DFColors.primary : DFColors.onSurfaceVariant)
                    
                    // Delete button
                    Button(action: {
                        onBulkDelete(selectedEntriesArray)
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                    }
                    .disabled(!canDelete)
                    .foregroundColor(canDelete ? DFColors.error : DFColors.onSurfaceVariant)
                    
                    // Cancel button
                    Button("Done") {
                        onToggleSelectionMode()
                    }
                    .font(DFTypography.labelMedium)
                    .foregroundColor(DFColors.primary)
                }
            }
            .padding(.horizontal, DFSpacing.Layout.screenPadding)
            .padding(.vertical, DFSpacing.md)
        }
        .background(DFColors.surface)
    }
    
    // MARK: - Normal Mode Toolbar
    private var normalModeToolbar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(DFColors.outline.opacity(0.2))
            
            HStack {
                Text("\(allEntries.count) entries")
                    .font(DFTypography.labelMedium)
                    .foregroundColor(DFColors.onSurfaceVariant)
                
                Spacer()
                
                if allEntries.count > 1 {
                    Button("Select") {
                        onToggleSelectionMode()
                    }
                    .font(DFTypography.labelMedium)
                    .foregroundColor(DFColors.primary)
                }
            }
            .padding(.horizontal, DFSpacing.Layout.screenPadding)
            .padding(.vertical, DFSpacing.sm)
        }
        .background(DFColors.surface)
    }
}

// MARK: - Selection Checkbox
public struct SelectionCheckbox: View {
    let isSelected: Bool
    let onToggle: () -> Void
    
    public var body: some View {
        Button(action: onToggle) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundColor(isSelected ? DFColors.primary : DFColors.onSurfaceVariant)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Bulk Action Sheet
public struct BulkActionSheet: View {
    let selectedCount: Int
    let onDelete: () -> Void
    let onExport: () -> Void
    let onCancel: () -> Void
    
    public var body: some View {
        VStack(spacing: DFSpacing.lg) {
            // Header
            VStack(spacing: DFSpacing.sm) {
                Text("Bulk Actions")
                    .font(DFTypography.headlineSmall)
                    .foregroundColor(DFColors.onSurface)
                
                Text("\(selectedCount) entries selected")
                    .font(DFTypography.bodyMedium)
                    .foregroundColor(DFColors.onSurfaceVariant)
            }
            
            // Actions
            VStack(spacing: DFSpacing.md) {
                // Export action
                Button(action: onExport) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export Selected")
                                .font(DFTypography.bodyMedium)
                            
                            Text("Export entries as JSON")
                                .font(DFTypography.labelSmall)
                                .foregroundColor(DFColors.onSurfaceVariant)
                        }
                        
                        Spacer()
                    }
                    .padding(DFSpacing.md)
                    .background(DFColors.surfaceVariant)
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                }
                .foregroundColor(DFColors.onSurface)
                
                // Delete action
                Button(action: onDelete) {
                    HStack {
                        Image(systemName: "trash")
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Delete Selected")
                                .font(DFTypography.bodyMedium)
                            
                            Text("Permanently remove entries")
                                .font(DFTypography.labelSmall)
                                .foregroundColor(DFColors.onSurfaceVariant)
                        }
                        
                        Spacer()
                    }
                    .padding(DFSpacing.md)
                    .background(DFColors.error.opacity(0.1))
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                }
                .foregroundColor(DFColors.error)
            }
            
            // Cancel
            Button("Cancel", action: onCancel)
                .font(DFTypography.bodyMedium)
                .foregroundColor(DFColors.onSurfaceVariant)
        }
        .padding(DFSpacing.xl)
    }
}

// MARK: - Previews
#if DEBUG
struct BulkActionsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BulkActionsView(
                selectedEntries: .constant(Set(["1", "2"])),
                allEntries: [],
                isSelectionMode: true,
                onToggleSelectionMode: {},
                onSelectAll: {},
                onDeselectAll: {},
                onBulkDelete: { _ in },
                onBulkExport: { _ in }
            )
            
            BulkActionsView(
                selectedEntries: .constant(Set()),
                allEntries: [],
                isSelectionMode: false,
                onToggleSelectionMode: {},
                onSelectAll: {},
                onDeselectAll: {},
                onBulkDelete: { _ in },
                onBulkExport: { _ in }
            )
        }
        .previewDisplayName("Bulk Actions")
    }
}
#endif