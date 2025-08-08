import SwiftUI

/// Design System Typography Scale
/// Following Material Design 3 type scale with iOS Human Interface Guidelines
@available(iOS 13.0, macOS 10.15, *)
public struct DFTypography {
    
    // MARK: - Display Styles
    public static let displayLarge = Font.system(size: 57, weight: .regular, design: .default)
    public static let displayMedium = Font.system(size: 45, weight: .regular, design: .default)
    public static let displaySmall = Font.system(size: 36, weight: .regular, design: .default)
    
    // MARK: - Headline Styles
    public static let headlineLarge = Font.system(size: 32, weight: .semibold, design: .default)
    public static let headlineMedium = Font.system(size: 28, weight: .semibold, design: .default)
    public static let headlineSmall = Font.system(size: 24, weight: .semibold, design: .default)
    
    // MARK: - Title Styles
    public static let titleLarge = Font.system(size: 22, weight: .medium, design: .default)
    public static let titleMedium = Font.system(size: 16, weight: .medium, design: .default)
    public static let titleSmall = Font.system(size: 14, weight: .medium, design: .default)
    
    // MARK: - Label Styles
    public static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    public static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
    public static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
    
    // MARK: - Body Styles
    public static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    public static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    public static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
    
    // MARK: - Form-Specific Typography
    public struct Form {
        public static let fieldLabel = labelLarge
        public static let fieldInput = bodyLarge
        public static let fieldPlaceholder = bodyLarge
        public static let fieldError = labelMedium
        public static let fieldHelper = labelSmall
        public static let sectionTitle = titleMedium
        public static let formTitle = headlineSmall
    }
    
    // MARK: - Navigation Typography
    public struct Navigation {
        public static let navigationTitle = titleLarge
        public static let navigationSubtitle = bodyMedium
        public static let tabLabel = labelMedium
    }
    
    // MARK: - Status Typography
    public struct Status {
        public static let errorMessage = labelMedium
        public static let successMessage = labelMedium
        public static let warningMessage = labelMedium
        public static let infoMessage = labelMedium
    }
}

// MARK: - Typography Modifiers
@available(iOS 13.0, macOS 10.15, *)
public extension View {
    
    /// Apply display typography style
    func displayLarge() -> some View {
        font(DFTypography.displayLarge)
    }
    
    func displayMedium() -> some View {
        font(DFTypography.displayMedium)
    }
    
    func displaySmall() -> some View {
        font(DFTypography.displaySmall)
    }
    
    /// Apply headline typography style
    func headlineLarge() -> some View {
        font(DFTypography.headlineLarge)
    }
    
    func headlineMedium() -> some View {
        font(DFTypography.headlineMedium)
    }
    
    func headlineSmall() -> some View {
        font(DFTypography.headlineSmall)
    }
    
    /// Apply title typography style
    func titleLarge() -> some View {
        font(DFTypography.titleLarge)
    }
    
    func titleMedium() -> some View {
        font(DFTypography.titleMedium)
    }
    
    func titleSmall() -> some View {
        font(DFTypography.titleSmall)
    }
    
    /// Apply label typography style
    func labelLarge() -> some View {
        font(DFTypography.labelLarge)
    }
    
    func labelMedium() -> some View {
        font(DFTypography.labelMedium)
    }
    
    func labelSmall() -> some View {
        font(DFTypography.labelSmall)
    }
    
    /// Apply body typography style
    func bodyLarge() -> some View {
        font(DFTypography.bodyLarge)
    }
    
    func bodyMedium() -> some View {
        font(DFTypography.bodyMedium)
    }
    
    func bodySmall() -> some View {
        font(DFTypography.bodySmall)
    }
}

// MARK: - Line Height and Letter Spacing
public extension DFTypography {
    
    struct LineHeight {
        public static let tight: CGFloat = 1.1
        public static let normal: CGFloat = 1.2
        public static let relaxed: CGFloat = 1.4
        public static let loose: CGFloat = 1.6
    }
    
    struct LetterSpacing {
        public static let tight: CGFloat = -0.5
        public static let normal: CGFloat = 0
        public static let wide: CGFloat = 0.5
        public static let wider: CGFloat = 1.0
    }
}

// MARK: - Accessibility Typography
public extension DFTypography {
    
    /// Dynamic type scaling support
    @available(iOS 13.0, macOS 10.15, *)
    struct Accessibility {
        public static func scaledFont(_ font: Font, category: UIContentSizeCategory = .large) -> Font {
            return font
        }
        
        /// Minimum touch target sizes for accessibility
        public static let minimumTouchTarget: CGFloat = 44
        
        /// Readable content widths
        public static let readableContentWidth: CGFloat = 672
    }
}