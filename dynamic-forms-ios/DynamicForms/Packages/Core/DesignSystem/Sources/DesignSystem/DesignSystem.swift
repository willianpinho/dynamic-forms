import SwiftUI

/// Main Design System module providing access to all design tokens and components
/// Following SOLID principles with clear separation of concerns
public struct DesignSystem {
    
    /// Design system version for compatibility tracking
    public static let version = "1.0.0"
    
    /// Initialize design system with default configuration
    public static func configure() {
        // Configure any global design system settings
        setupAccessibility()
        setupColorScheme()
    }
    
    // MARK: - Private Configuration
    private static func setupAccessibility() {
        // Configure accessibility settings
        // This could include dynamic type scaling, contrast adjustments, etc.
    }
    
    private static func setupColorScheme() {
        // Configure color scheme behavior
        // This could include dark mode preferences, high contrast modes, etc.
    }
}

// MARK: - Design System Theme Protocol
/// Protocol for applying consistent theming across the application
public protocol Themeable {
    func applyTheme() -> Self
}

// MARK: - Design System Constants
public extension DesignSystem {
    
    /// Animation durations for consistent motion design
    struct Animation {
        public static let fast: TimeInterval = 0.2
        public static let normal: TimeInterval = 0.3
        public static let slow: TimeInterval = 0.5
    }
    
    /// Border radius values
    struct BorderRadius {
        public static let small: CGFloat = 4
        public static let medium: CGFloat = 8
        public static let large: CGFloat = 12
        public static let extraLarge: CGFloat = 16
    }
    
    /// Elevation/Shadow values
    struct Elevation {
        public static let none: CGFloat = 0
        public static let low: CGFloat = 2
        public static let medium: CGFloat = 4
        public static let high: CGFloat = 8
        public static let extraHigh: CGFloat = 16
    }
    
    /// Opacity values for consistent transparency
    struct Opacity {
        public static let disabled: Double = 0.38
        public static let inactive: Double = 0.60
        public static let focused: Double = 0.87
        public static let active: Double = 1.0
    }
}
