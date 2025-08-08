import SwiftUI
import Domain
import DesignSystem
import UIComponents

/// Virtual form item view for O(1) performance optimization
/// Renders different item types efficiently in a single list
public struct VirtualFormItemView: View {
    
    // MARK: - Properties
    let item: VirtualFormItem
    let fieldValues: [String: String]
    let validationErrors: [String: String]
    let onFieldValueChange: (String, String) -> Void
    let onSaveDraft: () -> Void
    let onSubmitForm: () -> Void
    let onClearSuccessMessage: () -> Void
    
    // MARK: - Body
    public var body: some View {
        switch item {
        case .editWarning(_, let editContext):
            VirtualEditWarningView(editContext: editContext)
            
        case .sectionHeader(_, let section, let progress):
            VirtualSectionHeaderView(section: section, progress: progress)
            
        case .fieldItem(_, let field, _):
            VirtualFieldItemView(
                field: field,
                value: fieldValues[field.uuid] ?? "",
                validationError: validationErrors[field.uuid],
                onValueChange: { value in
                    onFieldValueChange(field.uuid, value)
                }
            )
            
        case .successMessage(_, let message):
            VirtualSuccessMessageView(
                message: message,
                onDismiss: onClearSuccessMessage
            )
            
        case .autoSaveStatus(_, let timestamp):
            VirtualAutoSaveStatusView(timestamp: timestamp)
        }
    }
}

// MARK: - Virtual Edit Warning View
private struct VirtualEditWarningView: View {
    let editContext: EditContext
    
    var body: some View {
        if editContext != .newEntry {
            Card(
                backgroundColor: DFColors.warning.opacity(0.1),
                borderColor: DFColors.warning.opacity(0.3)
            ) {
                HStack(spacing: DFSpacing.sm) {
                    Image(systemName: editContext.iconName)
                        .foregroundColor(DFColors.warning)
                        .font(.system(size: 20))
                    
                    Text(editContext.displayMessage)
                        .font(DFTypography.bodyMedium)
                        .foregroundColor(DFColors.onSurface)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                }
                .padding(DFSpacing.Layout.cardPadding)
            }
        }
    }
}

// MARK: - Virtual Section Header View
private struct VirtualSectionHeaderView: View {
    let section: FormSection
    let progress: SectionProgress
    
    var body: some View {
        if !section.title.isEmpty {
            Card(
                backgroundColor: DFColors.surfaceVariant,
                borderColor: DFColors.outline.opacity(0.2)
            ) {
                VStack(alignment: .leading, spacing: DFSpacing.sm) {
                    // Section title
                    if section.containsHTML {
                        HTMLTextView(html: section.title)
                    } else {
                        Text(section.title)
                            .font(DFTypography.headlineSmall)
                            .foregroundColor(DFColors.primary)
                    }
                    
                    // Progress indicator
                    if progress.totalFields > 0 {
                        HStack {
                            Text(progress.displayText)
                                .font(DFTypography.labelMedium)
                                .foregroundColor(DFColors.onSurfaceVariant)
                            
                            Spacer()
                            
                            ProgressView(value: progress.percentage)
                                .progressViewStyle(LinearProgressViewStyle(tint: DFColors.primary))
                                .frame(width: 80, height: 4)
                        }
                    }
                }
                .padding(DFSpacing.Layout.cardPadding)
            }
        }
    }
}

// MARK: - Virtual Field Item View
private struct VirtualFieldItemView: View {
    let field: FormField
    let value: String
    let validationError: String?
    let onValueChange: (String) -> Void
    
    var body: some View {
        DynamicFormFieldView(
            field: field.updateValue(value),
            validationError: validationError,
            onValueChanged: onValueChange
        )
    }
}

// MARK: - Virtual Success Message View
private struct VirtualSuccessMessageView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        Card(
            backgroundColor: DFColors.success.opacity(0.1),
            borderColor: DFColors.success.opacity(0.3)
        ) {
            HStack(spacing: DFSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DFColors.success)
                    .font(.system(size: 20))
                
                Text(message)
                    .font(DFTypography.bodyMedium)
                    .foregroundColor(DFColors.onSurface)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(DFColors.onSurfaceVariant)
                        .font(.system(size: 14))
                }
            }
            .padding(DFSpacing.Layout.cardPadding)
        }
    }
}

// MARK: - Virtual Auto-Save Status View
private struct VirtualAutoSaveStatusView: View {
    let timestamp: Date
    
    private var timeAgoText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: DFSpacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(DFColors.success)
                .font(.system(size: 12))
            
            Text("Auto-saved \(timeAgoText)")
                .font(DFTypography.labelSmall)
                .foregroundColor(DFColors.onSurfaceVariant)
            
            Spacer()
        }
        .padding(.horizontal, DFSpacing.sm)
        .padding(.vertical, DFSpacing.xs)
        .background(DFColors.surfaceVariant.opacity(0.5))
        .cornerRadius(DesignSystem.BorderRadius.small)
    }
}



// MARK: - Supporting Views

/// Card wrapper for consistent styling
private struct Card<Content: View>: View {
    let backgroundColor: Color
    let borderColor: Color
    let content: Content
    
    init(
        backgroundColor: Color = DFColors.surface,
        borderColor: Color = DFColors.outline.opacity(0.2),
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.content = content()
    }
    
    var body: some View {
        content
            .background(backgroundColor)
            .cornerRadius(DesignSystem.BorderRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(
                color: DFColors.shadow.opacity(0.1),
                radius: DesignSystem.Elevation.low,
                x: 0,
                y: 2
            )
    }
}

/// HTML text view for section titles with HTML content
private struct HTMLTextView: View {
    let html: String
    
    var body: some View {
        HTMLRendererFactory.createRenderer(
            htmlContent: html,
            baseFont: UIFont.preferredFont(forTextStyle: .headline),
            baseColor: UIColor.label
        )
    }
}

// MARK: - Previews
#if DEBUG
struct VirtualFormItemView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            LazyVStack(spacing: DFSpacing.sm) {
                // Edit Warning
                VirtualFormItemView(
                    item: .editWarning(editContext: .editingDraft),
                    fieldValues: [:],
                    validationErrors: [:],
                    onFieldValueChange: { _, _ in },
                    onSaveDraft: {},
                    onSubmitForm: {},
                    onClearSuccessMessage: {}
                )
                
                // Section Header
                VirtualFormItemView(
                    item: .sectionHeader(
                        id: "section1",
                        section: FormSection(
                            uuid: "section1",
                            title: "Personal Information",
                            from: 0,
                            to: 2,
                            index: 0
                        ),
                        progress: SectionProgress(filledFields: 1, totalFields: 3)
                    ),
                    fieldValues: [:],
                    validationErrors: [:],
                    onFieldValueChange: { _, _ in },
                    onSaveDraft: {},
                    onSubmitForm: {},
                    onClearSuccessMessage: {}
                )
                
                // Field Item
                VirtualFormItemView(
                    item: .fieldItem(
                        id: "field1",
                        field: FormField.textField(
                            uuid: "field1",
                            name: "name",
                            label: "Full Name",
                            required: true
                        ),
                        sectionId: "section1"
                    ),
                    fieldValues: ["field1": "John Doe"],
                    validationErrors: [:],
                    onFieldValueChange: { _, _ in },
                    onSaveDraft: {},
                    onSubmitForm: {},
                    onClearSuccessMessage: {}
                )
                
                // Success Message
                VirtualFormItemView(
                    item: .successMessage(message: "Form saved successfully!"),
                    fieldValues: [:],
                    validationErrors: [:],
                    onFieldValueChange: { _, _ in },
                    onSaveDraft: {},
                    onSubmitForm: {},
                    onClearSuccessMessage: {}
                )
                
                // Auto-save Status
                VirtualFormItemView(
                    item: .autoSaveStatus(timestamp: Date()),
                    fieldValues: [:],
                    validationErrors: [:],
                    onFieldValueChange: { _, _ in },
                    onSaveDraft: {},
                    onSubmitForm: {},
                    onClearSuccessMessage: {}
                )
            }
            .padding()
        }
        .previewDisplayName("Virtual Form Items")
    }
}
#endif