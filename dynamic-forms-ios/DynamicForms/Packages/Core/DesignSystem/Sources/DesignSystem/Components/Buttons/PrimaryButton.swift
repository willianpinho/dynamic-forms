import SwiftUI

/// Primary action button following design system guidelines
/// Implements SOLID principles with single responsibility for primary actions
@available(iOS 13.0, macOS 10.15, *)
public struct PrimaryButton: View {
    
    // MARK: - Properties
    private let title: String
    private let action: () -> Void
    private let isEnabled: Bool
    private let isLoading: Bool
    private let style: ButtonStyle
    
    // MARK: - Button Styles
    public enum ButtonStyle {
        case filled
        case outlined
        case text
    }
    
    // MARK: - Initialization
    public init(
        title: String,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        style: ButtonStyle = .filled,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.style = style
    }
    
    // MARK: - Body
    public var body: some View {
        Button(action: action) {
            HStack(spacing: DFSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                        .foregroundColor(textColor)
                }
                
                Text(title)
                    .font(DFTypography.labelLarge)
                    .foregroundColor(textColor)
                    .opacity(isLoading ? 0.6 : 1.0)
            }
            .frame(minHeight: DFSpacing.Interactive.buttonMinHeight)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, DFSpacing.Interactive.buttonPadding)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .disabled(!isEnabled || isLoading)
        .opacity(buttonOpacity)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
    
    // MARK: - Computed Properties
    private var backgroundColor: Color {
        switch style {
        case .filled:
            return isEnabled ? DFColors.Interactive.buttonPrimary : DFColors.Interactive.buttonDisabled
        case .outlined:
            return Color.clear
        case .text:
            return Color.clear
        }
    }
    
    private var textColor: Color {
        switch style {
        case .filled:
            return isEnabled ? DFColors.Interactive.buttonPrimaryText : DFColors.Interactive.buttonDisabledText
        case .outlined:
            return isEnabled ? DFColors.Interactive.buttonPrimary : DFColors.Interactive.buttonDisabledText
        case .text:
            return isEnabled ? DFColors.Interactive.buttonPrimary : DFColors.Interactive.buttonDisabledText
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .filled:
            return Color.clear
        case .outlined:
            return isEnabled ? DFColors.Interactive.buttonPrimary : DFColors.Interactive.buttonDisabled
        case .text:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .filled, .text:
            return 0
        case .outlined:
            return 1
        }
    }
    
    private var buttonOpacity: Double {
        isEnabled ? 1.0 : 0.6
    }
    
    // MARK: - Accessibility
    private var accessibilityLabel: String {
        if isLoading {
            return "\(title), loading"
        }
        return title
    }
    
    private var accessibilityHint: String {
        if !isEnabled {
            return "Button is disabled"
        } else if isLoading {
            return "Loading, please wait"
        }
        return "Double tap to activate"
    }
}

// MARK: - Secondary Button
/// Secondary action button with consistent styling
@available(iOS 13.0, macOS 10.15, *)
public struct SecondaryButton: View {
    private let title: String
    private let action: () -> Void
    private let isEnabled: Bool
    private let isLoading: Bool
    
    public init(
        title: String,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.isEnabled = isEnabled
        self.isLoading = isLoading
    }
    
    public var body: some View {
        PrimaryButton(
            title: title,
            isEnabled: isEnabled,
            isLoading: isLoading,
            style: .outlined,
            action: action
        )
    }
}

// MARK: - Text Button
/// Text-only button for tertiary actions
@available(iOS 13.0, macOS 10.15, *)
public struct TextButton: View {
    private let title: String
    private let action: () -> Void
    private let isEnabled: Bool
    
    public init(
        title: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.isEnabled = isEnabled
    }
    
    public var body: some View {
        PrimaryButton(
            title: title,
            isEnabled: isEnabled,
            isLoading: false,
            style: .text,
            action: action
        )
    }
}

// MARK: - Previews
#if DEBUG
@available(iOS 13.0, macOS 10.15, *)
struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DFSpacing.md) {
            PrimaryButton(title: "Primary Button") {}
            PrimaryButton(title: "Loading Button", isLoading: true) {}
            PrimaryButton(title: "Disabled Button", isEnabled: false) {}
            
            SecondaryButton(title: "Secondary Button") {}
            SecondaryButton(title: "Disabled Secondary", isEnabled: false) {}
            
            TextButton(title: "Text Button") {}
            TextButton(title: "Disabled Text", isEnabled: false) {}
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Button Variants")
    }
}
#endif