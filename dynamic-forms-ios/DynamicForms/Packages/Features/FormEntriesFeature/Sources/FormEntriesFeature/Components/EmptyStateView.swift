import SwiftUI
import DesignSystem

/// Empty state view for form entries
/// Shows contextual messages based on current filter and search state
public struct EmptyStateView: View {
    
    // MARK: - Properties
    let title: String
    let message: String
    let iconName: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    // MARK: - Initialization
    public init(
        title: String,
        message: String,
        iconName: String = "doc.text",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.iconName = iconName
        self.actionTitle = actionTitle
        self.action = action
    }
    
    // MARK: - Body
    public var body: some View {
        VStack(spacing: DFSpacing.lg) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 64, weight: .light))
                .foregroundColor(DFColors.onSurfaceVariant)
            
            // Text content
            VStack(spacing: DFSpacing.sm) {
                Text(title)
                    .font(DFTypography.headlineSmall)
                    .foregroundColor(DFColors.onSurface)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(DFTypography.bodyMedium)
                    .foregroundColor(DFColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Action button
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(title: actionTitle) {
                    action()
                }
                .padding(.horizontal, DFSpacing.xl)
            }
        }
        .padding(DFSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DFColors.background)
    }
}

// MARK: - Convenience Initializers
public extension EmptyStateView {
    
    /// Empty state for no entries
    static func noEntries(onCreateNew: @escaping () -> Void) -> EmptyStateView {
        return EmptyStateView(
            title: "No Entries Yet",
            message: "Start by creating your first entry for this form.",
            iconName: "doc.text",
            actionTitle: "Create New Entry",
            action: onCreateNew
        )
    }
    
    /// Empty state for no search results
    static func noSearchResults(searchText: String) -> EmptyStateView {
        return EmptyStateView(
            title: "No Results Found",
            message: "No entries match your search for '\(searchText)'. Try different keywords or clear the search.",
            iconName: "magnifyingglass"
        )
    }
    
    /// Empty state for no drafts
    static func noDrafts(onCreateNew: @escaping () -> Void) -> EmptyStateView {
        return EmptyStateView(
            title: "No Draft Entries",
            message: "You don't have any draft entries for this form. Start creating one now.",
            iconName: "doc.text.fill",
            actionTitle: "Create New Entry",
            action: onCreateNew
        )
    }
    
    /// Empty state for no completed entries
    static func noCompleted() -> EmptyStateView {
        return EmptyStateView(
            title: "No Completed Entries",
            message: "You haven't completed any entries for this form yet.",
            iconName: "checkmark.circle"
        )
    }
    
    /// Empty state for no edit drafts
    static func noEditDrafts() -> EmptyStateView {
        return EmptyStateView(
            title: "No Edit Drafts",
            message: "You don't have any edit drafts. Create one by editing a completed entry.",
            iconName: "pencil.circle"
        )
    }
}

// MARK: - Previews
#if DEBUG
struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DFSpacing.lg) {
            EmptyStateView.noEntries(onCreateNew: {})
            
            EmptyStateView.noSearchResults(searchText: "test")
            
            EmptyStateView.noDrafts(onCreateNew: {})
            
            EmptyStateView.noCompleted()
        }
        .previewDisplayName("Empty States")
    }
}
#endif