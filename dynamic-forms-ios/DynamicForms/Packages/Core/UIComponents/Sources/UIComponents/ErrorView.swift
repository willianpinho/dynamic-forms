import SwiftUI
import DesignSystem

/// Error view component for displaying error states consistently
/// Following Single Responsibility Principle for error presentation
public struct ErrorView: View {
    
    // MARK: - Properties
    private let title: String
    private let message: String
    private let style: ErrorStyle
    private let retryAction: (() -> Void)?
    private let dismissAction: (() -> Void)?
    
    // MARK: - Error Styles
    public enum ErrorStyle {
        case inline
        case fullscreen
        case banner
        case card
    }
    
    // MARK: - Initialization
    public init(
        title: String = "Error",
        message: String,
        style: ErrorStyle = .inline,
        retryAction: (() -> Void)? = nil,
        dismissAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.style = style
        self.retryAction = retryAction
        self.dismissAction = dismissAction
    }
    
    // MARK: - Body
    public var body: some View {
        switch style {
        case .inline:
            inlineErrorView
        case .fullscreen:
            fullscreenErrorView
        case .banner:
            bannerErrorView
        case .card:
            cardErrorView
        }
    }
    
    // MARK: - Error View Styles
    
    private var inlineErrorView: some View {
        HStack(spacing: DFSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(DFColors.error)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: DFSpacing.xxs) {
                Text(title)
                    .font(DFTypography.labelMedium)
                    .foregroundColor(DFColors.error)
                
                Text(message)
                    .font(DFTypography.bodySmall)
                    .foregroundColor(DFColors.onErrorContainer)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            if let dismissAction = dismissAction {
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .foregroundColor(DFColors.onErrorContainer)
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(DFSpacing.sm)
        .background(DFColors.errorContainer)
        .cornerRadius(DesignSystem.BorderRadius.small)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.small)
                .stroke(DFColors.error.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var fullscreenErrorView: some View {
        VStack(spacing: DFSpacing.xl) {
            VStack(spacing: DFSpacing.lg) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(DFColors.error)
                
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
            }
            
            actionButtons
        }
        .padding(DFSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DFColors.background)
    }
    
    private var bannerErrorView: some View {
        HStack(spacing: DFSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(DFColors.onError)
                .font(.system(size: 14))
            
            Text(message)
                .font(DFTypography.labelMedium)
                .foregroundColor(DFColors.onError)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            if let dismissAction = dismissAction {
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .foregroundColor(DFColors.onError)
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, DFSpacing.md)
        .padding(.vertical, DFSpacing.sm)
        .background(DFColors.error)
        .animation(.easeInOut(duration: DesignSystem.Animation.fast), value: message)
    }
    
    private var cardErrorView: some View {
        VStack(spacing: DFSpacing.md) {
            HStack(spacing: DFSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(DFColors.error)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: DFSpacing.xxs) {
                    Text(title)
                        .font(DFTypography.titleSmall)
                        .foregroundColor(DFColors.onSurface)
                    
                    Text(message)
                        .font(DFTypography.bodyMedium)
                        .foregroundColor(DFColors.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            
            if retryAction != nil || dismissAction != nil {
                actionButtons
            }
        }
        .padding(DFSpacing.md)
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
                .stroke(DFColors.error.opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: DFSpacing.sm) {
            if let retryAction = retryAction {
                SecondaryButton(title: "Retry", action: retryAction)
            }
            
            if let dismissAction = dismissAction {
                TextButton(title: "Dismiss", action: dismissAction)
            }
        }
    }
}

// MARK: - Network Error View
public struct NetworkErrorView: View {
    private let retryAction: (() -> Void)?
    
    public init(retryAction: (() -> Void)? = nil) {
        self.retryAction = retryAction
    }
    
    public var body: some View {
        ErrorView(
            title: "Connection Error",
            message: "Please check your internet connection and try again.",
            style: .fullscreen,
            retryAction: retryAction
        )
    }
}

// MARK: - Empty State Error View
public struct EmptyStateView: View {
    private let title: String
    private let message: String
    private let iconName: String
    private let actionTitle: String?
    private let action: (() -> Void)?
    
    public init(
        title: String,
        message: String,
        iconName: String = "tray",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.iconName = iconName
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: DFSpacing.xl) {
            VStack(spacing: DFSpacing.lg) {
                Image(systemName: iconName)
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(DFColors.onSurfaceVariant)
                
                VStack(spacing: DFSpacing.sm) {
                    Text(title)
                        .font(DFTypography.headlineSmall)
                        .foregroundColor(DFColors.onSurface)
                        .multilineTextAlignment(.center)
                    
                    Text(message)
                        .font(DFTypography.bodyMedium)
                        .foregroundColor(DFColors.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
            }
            
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(title: actionTitle, action: action)
                    .padding(.horizontal, DFSpacing.xl)
            }
        }
        .padding(DFSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DFColors.background)
    }
}

// MARK: - Field Error View
public struct FieldErrorView: View {
    private let message: String
    
    public init(message: String) {
        self.message = message
    }
    
    public var body: some View {
        HStack(spacing: DFSpacing.xs) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(DFColors.error)
                .font(.system(size: 12))
            
            Text(message)
                .font(DFTypography.labelSmall)
                .foregroundColor(DFColors.error)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.top, DFSpacing.xs)
    }
}

// MARK: - Error Alert Modifier
public extension View {
    
    /// Show error alert when condition is true
    func errorAlert(
        isPresented: Binding<Bool>,
        error: Error?,
        retryAction: (() -> Void)? = nil
    ) -> some View {
        alert("Error", isPresented: isPresented) {
            if let retryAction = retryAction {
                Button("Retry", action: retryAction)
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text((error as? Swift.Error)?.localizedDescription ?? "An unknown error occurred")
        }
    }
    
    /// Show error banner at top of screen
    func errorBanner(
        error: String?,
        dismissAction: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            if let error = error {
                ErrorView(
                    message: error,
                    style: .banner,
                    dismissAction: dismissAction
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            self
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: error)
    }
}

// MARK: - Previews
#if DEBUG
struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DFSpacing.lg) {
            ErrorView(
                title: "Validation Error",
                message: "Please fill in all required fields before submitting.",
                style: .inline,
                dismissAction: {}
            )
            
            ErrorView(
                title: "Network Error",
                message: "Unable to connect to the server. Please check your internet connection.",
                style: .card,
                retryAction: {},
                dismissAction: {}
            )
            
            FieldErrorView(message: "This field is required")
            
            EmptyStateView(
                title: "No Forms Available",
                message: "You don't have any forms yet. Create your first form to get started.",
                iconName: "doc.text",
                actionTitle: "Create Form",
                action: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Error States")
    }
}
#endif