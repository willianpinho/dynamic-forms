import SwiftUI
import Domain
import DesignSystem

/// Sort options view for form entries
/// Provides different sorting criteria and order options
public struct SortOptionsView: View {
    
    // MARK: - Properties
    @Binding var selectedSortOption: EntrySortOption
    let onDismiss: () -> Void
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Sort options
                sortOptionsSection
                
                Spacer()
            }
            .background(DFColors.background)
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    onDismiss()
                }
                .foregroundColor(DFColors.primary)
                
                Spacer()
                
                Text("Sort Entries")
                    .font(DFTypography.headlineSmall)
                    .foregroundColor(DFColors.onSurface)
                
                Spacer()
                
                Button("Done") {
                    onDismiss()
                }
                .foregroundColor(DFColors.primary)
            }
            .padding(.horizontal, DFSpacing.Layout.screenPadding)
            .padding(.vertical, DFSpacing.md)
            
            Divider()
                .background(DFColors.outline.opacity(0.2))
        }
    }
    
    // MARK: - Sort Options Section
    private var sortOptionsSection: some View {
        VStack(spacing: 0) {
            ForEach(EntrySortOption.allCases, id: \.self) { option in
                SortOptionRow(
                    option: option,
                    isSelected: selectedSortOption == option,
                    onSelect: {
                        selectedSortOption = option
                    }
                )
            }
        }
        .padding(.top, DFSpacing.md)
    }
}

// MARK: - Sort Option Row
private struct SortOptionRow: View {
    let option: EntrySortOption
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DFSpacing.md) {
                // Icon
                Image(systemName: option.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? DFColors.primary : DFColors.onSurfaceVariant)
                    .frame(width: 24)
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.displayName)
                        .font(DFTypography.bodyMedium)
                        .foregroundColor(DFColors.onSurface)
                        .multilineTextAlignment(.leading)
                    
                    Text(option.description)
                        .font(DFTypography.labelSmall)
                        .foregroundColor(DFColors.onSurfaceVariant)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DFColors.primary)
                }
            }
            .padding(.horizontal, DFSpacing.Layout.screenPadding)
            .padding(.vertical, DFSpacing.md)
        }
        .buttonStyle(PlainButtonStyle())
        .background(isSelected ? DFColors.primary.opacity(0.1) : Color.clear)
    }
}

// MARK: - Entry Sort Option Extensions
public extension EntrySortOption {
    
    var iconName: String {
        switch self {
        case .updatedDateDescending, .updatedDateAscending:
            return "clock"
        case .createdDateDescending, .createdDateAscending:
            return "calendar"
        }
    }
    
    var description: String {
        switch self {
        case .updatedDateDescending:
            return "Most recently modified entries first"
        case .updatedDateAscending:
            return "Least recently modified entries first"
        case .createdDateDescending:
            return "Newest entries first"
        case .createdDateAscending:
            return "Oldest entries first"
        }
    }
}

// MARK: - Sort Button
public struct SortButton: View {
    let currentSort: EntrySortOption
    let onTap: () -> Void
    
    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: DFSpacing.xs) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 14))
                
                Text("Sort")
                    .font(DFTypography.labelSmall)
            }
            .padding(.horizontal, DFSpacing.sm)
            .padding(.vertical, DFSpacing.xs)
            .background(DFColors.surfaceVariant)
            .foregroundColor(DFColors.onSurfaceVariant)
            .cornerRadius(DesignSystem.BorderRadius.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews
#if DEBUG
struct SortOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        SortOptionsView(
            selectedSortOption: .constant(.updatedDateDescending),
            onDismiss: {}
        )
        .previewDisplayName("Sort Options")
    }
}
#endif
