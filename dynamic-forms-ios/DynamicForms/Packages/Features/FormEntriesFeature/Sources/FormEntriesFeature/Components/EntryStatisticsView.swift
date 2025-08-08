import SwiftUI
import Domain
import DesignSystem

/// Statistics view for form entries
/// Shows overview of drafts, submitted, and completion rates
public struct EntryStatisticsView: View {
    
    // MARK: - Properties
    let statistics: EntryStatistics
    
    // MARK: - Body
    public var body: some View {
        VStack(spacing: DFSpacing.md) {
            // Header
            HStack {
                Text("Entry Statistics")
                    .font(DFTypography.headlineSmall)
                    .foregroundColor(DFColors.onSurface)
                
                Spacer()
            }
            
            // Statistics Cards
            LazyVGrid(columns: gridColumns, spacing: DFSpacing.sm) {
                StatCard(
                    title: "Total",
                    value: "\(statistics.totalEntries)",
                    subtitle: "entries",
                    color: DFColors.primary,
                    icon: "doc.text"
                )
                
                StatCard(
                    title: "Drafts",
                    value: "\(statistics.draftEntries)",
                    subtitle: "in progress",
                    color: DFColors.warning,
                    icon: "pencil.circle"
                )
                
                StatCard(
                    title: "Completed",
                    value: "\(statistics.completedEntries)",
                    subtitle: "submitted",
                    color: DFColors.success,
                    icon: "checkmark.circle"
                )
                
                StatCard(
                    title: "Edit Drafts",
                    value: "\(statistics.editDraftEntries)",
                    subtitle: "revisions",
                    color: DFColors.secondary,
                    icon: "arrow.triangle.2.circlepath"
                )
            }
            
            // Progress Indicators
            VStack(spacing: DFSpacing.sm) {
                ProgressIndicator(
                    title: "Completion Rate",
                    percentage: statistics.completionRate,
                    color: DFColors.success
                )
                
                ProgressIndicator(
                    title: "Draft Rate",
                    percentage: statistics.draftRate,
                    color: DFColors.warning
                )
            }
            
            // Last Updated
            if let lastUpdated = statistics.lastUpdated {
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(DFColors.onSurfaceVariant)
                    
                    Text("Last updated: \(lastUpdated, style: .relative)")
                        .font(DFTypography.labelSmall)
                        .foregroundColor(DFColors.onSurfaceVariant)
                    
                    Spacer()
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
    }
    
    // MARK: - Grid Configuration
    private var gridColumns: [GridItem] {
        return Array(repeating: GridItem(.flexible(), spacing: DFSpacing.sm), count: 2)
    }
}

// MARK: - Stat Card
private struct StatCard: View {
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

// MARK: - Progress Indicator
private struct ProgressIndicator: View {
    let title: String
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DFSpacing.xs) {
            HStack {
                Text(title)
                    .font(DFTypography.labelMedium)
                    .foregroundColor(DFColors.onSurface)
                
                Spacer()
                
                Text("\(Int(percentage * 100))%")
                    .font(DFTypography.labelSmall)
                    .foregroundColor(DFColors.onSurfaceVariant)
            }
            
            ProgressView(value: percentage)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(height: 4)
        }
    }
}

// MARK: - Empty Statistics View
public struct EmptyStatisticsView: View {
    
    public var body: some View {
        VStack(spacing: DFSpacing.md) {
            Image(systemName: "chart.bar")
                .font(.system(size: 48))
                .foregroundColor(DFColors.onSurfaceVariant)
            
            Text("No Entries Yet")
                .font(DFTypography.headlineSmall)
                .foregroundColor(DFColors.onSurface)
            
            Text("Create your first entry to see statistics")
                .font(DFTypography.bodyMedium)
                .foregroundColor(DFColors.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .padding(DFSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(DFColors.surface)
        .cornerRadius(DesignSystem.BorderRadius.medium)
        .shadow(
            color: DFColors.shadow.opacity(0.1),
            radius: DesignSystem.Elevation.low,
            x: 0,
            y: 2
        )
    }
}

// MARK: - Previews
#if DEBUG
struct EntryStatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DFSpacing.lg) {
            EntryStatisticsView(
                statistics: EntryStatistics(
                    totalEntries: 15,
                    draftEntries: 5,
                    editDraftEntries: 2,
                    completedEntries: 8,
                    submittedEntries: 0,
                    lastUpdated: Date()
                )
            )
            
            EmptyStatisticsView()
        }
        .padding()
        .background(DFColors.background)
        .previewDisplayName("Entry Statistics")
    }
}
#endif