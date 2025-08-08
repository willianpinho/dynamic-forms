import SwiftUI
import Domain
import DesignSystem

/// Detailed statistics view for form entries
/// Shows comprehensive overview of drafts, submitted, and completion rates
public struct EntryStatisticsDetailView: View {
    
    // MARK: - Properties
    let statistics: EntryStatistics
    let formTitle: String
    
    // MARK: - State
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    public init(statistics: EntryStatistics, formTitle: String) {
        self.statistics = statistics
        self.formTitle = formTitle
    }
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DFSpacing.lg) {
                    // Form Info Header
                    formInfoHeader
                    
                    // Overview Cards
                    overviewSection
                    
                    // Progress Charts
                    progressSection
                    
                    // Detailed Breakdown
                    detailedBreakdownSection
                    
                    // Last Updated Info
                    lastUpdatedSection
                }
                .padding(.horizontal, DFSpacing.Layout.screenPadding)
                .padding(.vertical, DFSpacing.md)
            }
            .navigationTitle("Entry Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DFColors.primary)
                }
            }
        }
    }
    
    // MARK: - Form Info Header
    private var formInfoHeader: some View {
        VStack(spacing: DFSpacing.sm) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(DFColors.primary)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(formTitle)
                        .font(DFTypography.headlineSmall)
                        .foregroundColor(DFColors.onSurface)
                        .multilineTextAlignment(.leading)
                    
                    Text("Entry Statistics Overview")
                        .font(DFTypography.bodyMedium)
                        .foregroundColor(DFColors.onSurfaceVariant)
                }
                
                Spacer()
            }
            .padding(.vertical, DFSpacing.sm)
            
            Divider()
                .background(DFColors.outline.opacity(0.3))
        }
    }
    
    // MARK: - Overview Section
    private var overviewSection: some View {
        VStack(spacing: DFSpacing.md) {
            SectionHeader(title: "Overview", icon: "chart.bar.fill")
            
            LazyVGrid(columns: gridColumns, spacing: DFSpacing.sm) {
                StatCardView(
                    title: "Total Entries",
                    value: "\(statistics.totalEntries)",
                    subtitle: "all entries",
                    color: DFColors.primary,
                    icon: "doc.text"
                )
                
                StatCardView(
                    title: "Drafts",
                    value: "\(statistics.draftEntries)",
                    subtitle: "in progress",
                    color: DFColors.warning,
                    icon: "pencil.circle"
                )
                
                StatCardView(
                    title: "Completed",
                    value: "\(statistics.completedEntries)",
                    subtitle: "submitted",
                    color: DFColors.success,
                    icon: "checkmark.circle"
                )
                
                StatCardView(
                    title: "Edit Drafts",
                    value: "\(statistics.editDraftEntries)",
                    subtitle: "revisions",
                    color: DFColors.secondary,
                    icon: "arrow.triangle.2.circlepath"
                )
            }
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: DFSpacing.md) {
            SectionHeader(title: "Progress Analysis", icon: "chart.pie.fill")
            
            VStack(spacing: DFSpacing.md) {
                // Completion Rate
                ProgressIndicatorView(
                    title: "Completion Rate",
                    progress: statistics.completionRate,
                    color: DFColors.success,
                    description: "\(Int(statistics.completionRate * 100))% of entries are completed"
                )
                
                // Draft Rate
                ProgressIndicatorView(
                    title: "Draft Rate",
                    progress: statistics.draftRate,
                    color: DFColors.warning,
                    description: "\(Int(statistics.draftRate * 100))% of entries are in draft state"
                )
            }
        }
    }
    
    // MARK: - Detailed Breakdown Section
    private var detailedBreakdownSection: some View {
        VStack(spacing: DFSpacing.md) {
            SectionHeader(title: "Detailed Breakdown", icon: "list.bullet.rectangle")
            
            VStack(spacing: DFSpacing.sm) {
                DetailRowView(
                    title: "Total Entries",
                    value: "\(statistics.totalEntries)",
                    icon: "doc.text",
                    color: DFColors.primary
                )
                
                DetailRowView(
                    title: "New Drafts",
                    value: "\(statistics.draftEntries)",
                    icon: "pencil.circle",
                    color: DFColors.warning
                )
                
                DetailRowView(
                    title: "Edit Drafts",
                    value: "\(statistics.editDraftEntries)",
                    icon: "arrow.triangle.2.circlepath",
                    color: DFColors.secondary
                )
                
                DetailRowView(
                    title: "Completed Entries",
                    value: "\(statistics.completedEntries)",
                    icon: "checkmark.circle",
                    color: DFColors.success
                )
                
                DetailRowView(
                    title: "Submitted Entries",
                    value: "\(statistics.submittedEntries)",
                    icon: "paperplane.circle",
                    color: DFColors.primary
                )
            }
            .padding(.vertical, DFSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                    .fill(DFColors.surfaceVariant.opacity(0.5))
            )
        }
    }
    
    // MARK: - Last Updated Section
    private var lastUpdatedSection: some View {
        VStack(spacing: DFSpacing.sm) {
            if let lastUpdated = statistics.lastUpdated {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(DFColors.onSurfaceVariant)
                        .font(.caption)
                    
                    Text("Last updated: \(lastUpdated, style: .relative)")
                        .font(DFTypography.bodySmall)
                        .foregroundColor(DFColors.onSurfaceVariant)
                    
                    Spacer()
                }
            }
        }
        .padding(.top, DFSpacing.md)
    }
    
    // MARK: - Supporting Views
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: DFSpacing.sm),
            GridItem(.flexible(), spacing: DFSpacing.sm)
        ]
    }
}

// MARK: - Section Header View
private struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(DFColors.primary)
                .font(.headline)
            
            Text(title)
                .font(DFTypography.headlineSmall)
                .foregroundColor(DFColors.onSurface)
            
            Spacer()
        }
    }
}

// MARK: - Progress Indicator View
private struct ProgressIndicatorView: View {
    let title: String
    let progress: Double
    let color: Color
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DFSpacing.sm) {
            HStack {
                Text(title)
                    .font(DFTypography.bodyMedium)
                    .foregroundColor(DFColors.onSurface)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(DFTypography.bodyMedium.weight(.semibold))
                    .foregroundColor(color)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(y: 2.0)
            
            Text(description)
                .font(DFTypography.bodySmall)
                .foregroundColor(DFColors.onSurfaceVariant)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, DFSpacing.sm)
        .padding(.horizontal, DFSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Detail Row View
private struct DetailRowView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DFSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.body)
                .frame(width: 24)
            
            Text(title)
                .font(DFTypography.bodyMedium)
                .foregroundColor(DFColors.onSurface)
            
            Spacer()
            
            Text(value)
                .font(DFTypography.bodyMedium.weight(.semibold))
                .foregroundColor(DFColors.onSurface)
        }
        .padding(.horizontal, DFSpacing.md)
        .padding(.vertical, DFSpacing.sm)
    }
}

// MARK: - Stat Card View
private struct StatCardView: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: DFSpacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(DFTypography.headlineSmall)
                        .foregroundColor(DFColors.onSurface)
                    
                    Text(title)
                        .font(DFTypography.labelMedium)
                        .foregroundColor(DFColors.onSurfaceVariant)
                    
                    Text(subtitle)
                        .font(DFTypography.labelSmall)
                        .foregroundColor(DFColors.onSurfaceVariant)
                }
                
                Spacer()
            }
        }
        .padding(DFSpacing.sm)
        .background(color.opacity(0.1))
        .cornerRadius(DesignSystem.BorderRadius.small)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.small)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#if DEBUG
struct EntryStatisticsDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EntryStatisticsDetailView(
            statistics: EntryStatistics(
                totalEntries: 25,
                draftEntries: 8,
                editDraftEntries: 3,
                completedEntries: 14,
                submittedEntries: 14,
                lastUpdated: Date()
            ),
            formTitle: "Customer Survey Form"
        )
    }
}
#endif