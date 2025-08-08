import SwiftUI

/// Design System Color Tokens
/// Following Material Design 3 principles with enterprise-grade accessibility
@available(iOS 13.0, macOS 10.15, *)
public struct DFColors {
    
    // MARK: - Primary Colors
    public static let primary = Fallback.primary
    public static let onPrimary = Fallback.onPrimary
    public static let primaryContainer = Color.blue.opacity(0.1)
    public static let onPrimaryContainer = Color.blue
    
    // MARK: - Secondary Colors
    public static let secondary = Color.teal
    public static let onSecondary = Color.white
    public static let secondaryContainer = Color.teal.opacity(0.1)
    public static let onSecondaryContainer = Color.teal
    
    // MARK: - Surface Colors
    public static let surface = Fallback.surface
    public static let onSurface = Fallback.onSurface
    public static let surfaceVariant = Color(.secondarySystemBackground)
    public static let onSurfaceVariant = Color(.secondaryLabel)
    
    // MARK: - Background Colors
    public static let background = Color(.systemBackground)
    public static let onBackground = Color(.label)
    
    // MARK: - Error Colors
    public static let error = Fallback.error
    public static let onError = Color.white
    public static let errorContainer = Color.red.opacity(0.1)
    public static let onErrorContainer = Color.red
    
    // MARK: - Success Colors (Custom)
    public static let success = Fallback.success
    public static let onSuccess = Color.white
    public static let successContainer = Color.green.opacity(0.1)
    public static let onSuccessContainer = Color.green

    // MARK: - Warning Colors (Custom)
    public static let warning = Fallback.warning
    public static let onWarning = Color.white
    public static let warningContainer = Color.orange.opacity(0.1)
    public static let onWarningContainer = Color.orange
    
    // MARK: - Outline Colors
    public static let outline = Fallback.outline
    public static let outlineVariant = Color(.separator).opacity(0.5)
    
    // MARK: - Shadow and Scrim
    public static let shadow = Color.black
    public static let scrim = Color.black.opacity(0.32)
    
    // MARK: - Fallback Colors
    /// Fallback colors when bundle colors are not available
    @available(iOS 13.0, macOS 10.15, *)
    public struct Fallback {
        public static let primary = Color.blue
        public static let onPrimary = Color.white
        #if canImport(UIKit)
        public static let surface = Color(UIColor.systemBackground)
        public static let onSurface = Color(UIColor.label)
        public static let error = Color.red
        public static let success = Color.green
        public static let warning = Color.orange
        public static let outline = Color(UIColor.separator)
        #else
        public static let surface = Color.white
        public static let onSurface = Color.black
        public static let error = Color.red
        public static let success = Color.green
        public static let warning = Color.orange
        public static let outline = Color.gray
        #endif
    }
}

// MARK: - Color Extensions
@available(iOS 13.0, macOS 10.15, *)
public extension Color {
    /// Initialize color with fallback support
    init(_ name: String, bundle: Bundle?) {
        #if canImport(UIKit)
        if let bundle = bundle,
           let color = UIColor(named: name, in: bundle, compatibleWith: nil) {
            self.init(color)
        } else {
            // Fallback to system colors
            switch name {
            case "Primary": self = DFColors.Fallback.primary
            case "OnPrimary": self = DFColors.Fallback.onPrimary
            case "Surface": self = DFColors.Fallback.surface
            case "OnSurface": self = DFColors.Fallback.onSurface
            case "Error": self = DFColors.Fallback.error
            case "Success": self = DFColors.Fallback.success
            case "Warning": self = DFColors.Fallback.warning
            case "Outline": self = DFColors.Fallback.outline
            default: self = DFColors.Fallback.onSurface
            }
        }
        #else
        // Fallback for non-UIKit platforms
        switch name {
        case "Primary": self = DFColors.Fallback.primary
        case "OnPrimary": self = DFColors.Fallback.onPrimary
        case "Surface": self = DFColors.Fallback.surface
        case "OnSurface": self = DFColors.Fallback.onSurface
        case "Error": self = DFColors.Fallback.error
        case "Success": self = DFColors.Fallback.success
        case "Warning": self = DFColors.Fallback.warning
        case "Outline": self = DFColors.Fallback.outline
        default: self = DFColors.Fallback.onSurface
        }
        #endif
    }
}

// MARK: - Semantic Color Roles
public extension DFColors {
    
    /// Form-specific color roles
    struct Form {
        public static let fieldBackground = surfaceVariant
        public static let fieldBorder = outline
        public static let fieldFocusedBorder = primary
        public static let fieldErrorBorder = error
        public static let fieldText = onSurface
        public static let fieldPlaceholder = onSurfaceVariant
        public static let fieldErrorText = error
        public static let requiredIndicator = error
    }
    
    /// Interactive element colors
    struct Interactive {
        public static let buttonPrimary = primary
        public static let buttonPrimaryText = onPrimary
        public static let buttonSecondary = secondaryContainer
        public static let buttonSecondaryText = onSecondaryContainer
        public static let buttonDisabled = surfaceVariant
        public static let buttonDisabledText = onSurfaceVariant
        public static let linkText = primary
        public static let linkPressed = primaryContainer
    }
    
    /// Status and feedback colors
    struct Status {
        public static let draft = warning
        public static let submitted = success
        public static let error = DFColors.error
        public static let loading = primary
        public static let empty = onSurfaceVariant
    }
}
