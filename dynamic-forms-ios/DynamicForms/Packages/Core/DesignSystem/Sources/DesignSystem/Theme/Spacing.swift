import SwiftUI

/// Design System Spacing Tokens
/// Consistent spacing scale following 8pt grid system
public struct DFSpacing {
    
    // MARK: - Base Spacing Scale
    public static let none: CGFloat = 0
    public static let xxs: CGFloat = 2    // 0.125rem
    public static let xs: CGFloat = 4     // 0.25rem
    public static let sm: CGFloat = 8     // 0.5rem
    public static let md: CGFloat = 16    // 1rem
    public static let lg: CGFloat = 24    // 1.5rem
    public static let xl: CGFloat = 32    // 2rem
    public static let xxl: CGFloat = 48   // 3rem
    public static let xxxl: CGFloat = 64  // 4rem
    
    // MARK: - Form-Specific Spacing
    public struct Form {
        public static let fieldVertical: CGFloat = sm        // 8pt
        public static let fieldHorizontal: CGFloat = md      // 16pt
        public static let fieldInternalPadding: CGFloat = md // 16pt
        public static let sectionSpacing: CGFloat = xl       // 32pt
        public static let formPadding: CGFloat = md          // 16pt
        public static let errorMessageTop: CGFloat = xs      // 4pt
        public static let labelBottom: CGFloat = xs          // 4pt
    }
    
    // MARK: - Layout Spacing
    public struct Layout {
        public static let screenPadding: CGFloat = md        // 16pt
        public static let contentSpacing: CGFloat = lg       // 24pt
        public static let cardPadding: CGFloat = md          // 16pt
        public static let cardSpacing: CGFloat = sm          // 8pt
        public static let sectionSpacing: CGFloat = xl       // 32pt
    }
    
    // MARK: - Interactive Spacing
    public struct Interactive {
        public static let buttonPadding: CGFloat = md        // 16pt
        public static let buttonMinHeight: CGFloat = 44      // Minimum touch target
        public static let buttonSpacing: CGFloat = sm        // 8pt
        public static let touchTargetMinimum: CGFloat = 44   // iOS HIG minimum
    }
    
    // MARK: - Navigation Spacing
    public struct Navigation {
        public static let barPadding: CGFloat = md           // 16pt
        public static let tabBarHeight: CGFloat = 83         // Standard tab bar
        public static let navigationBarHeight: CGFloat = 44  // Standard nav bar
    }
}

// MARK: - Spacing Modifiers
@available(iOS 13.0, macOS 10.15, *)
public extension View {
    
    /// Apply padding using design system spacing tokens
    func dfPadding(_ spacing: CGFloat) -> some View {
        padding(spacing)
    }
    
    func dfPaddingHorizontal(_ spacing: CGFloat) -> some View {
        padding(.horizontal, spacing)
    }
    
    func dfPaddingVertical(_ spacing: CGFloat) -> some View {
        padding(.vertical, spacing)
    }
    
    /// Form-specific padding modifiers
    func formPadding() -> some View {
        padding(DFSpacing.Form.formPadding)
    }
    
    func fieldPadding() -> some View {
        padding(.horizontal, DFSpacing.Form.fieldHorizontal)
            .padding(.vertical, DFSpacing.Form.fieldVertical)
    }
    
    /// Layout-specific spacing modifiers
    func screenPadding() -> some View {
        padding(DFSpacing.Layout.screenPadding)
    }
    
    func contentSpacing() -> some View {
        padding(DFSpacing.Layout.contentSpacing)
    }
    
    func cardPadding() -> some View {
        padding(DFSpacing.Layout.cardPadding)
    }
}

// MARK: - Geometric Spacing Utilities
public extension DFSpacing {
    
    /// Grid system utilities
    struct Grid {
        public static let baseUnit: CGFloat = 8
        
        public static func spacing(_ multiplier: Int) -> CGFloat {
            return baseUnit * CGFloat(multiplier)
        }
        
        /// Common grid spacings
        public static let grid1 = spacing(1)   // 8pt
        public static let grid2 = spacing(2)   // 16pt
        public static let grid3 = spacing(3)   // 24pt
        public static let grid4 = spacing(4)   // 32pt
        public static let grid6 = spacing(6)   // 48pt
        public static let grid8 = spacing(8)   // 64pt
    }
    
    /// Safe area and device-specific spacing
    struct SafeArea {
        public static let bottom: CGFloat = 34        // iPhone X+ home indicator
        public static let top: CGFloat = 47           // Status bar + safe area
        public static let notchTop: CGFloat = 44      // Notch devices
        public static let homeIndicator: CGFloat = 34 // Home indicator height
    }
    
    /// Responsive spacing based on device size
    struct Responsive {
        public static func spacing(compact: CGFloat, regular: CGFloat) -> CGFloat {
            // This would typically use size classes or device detection
            // For now, return regular spacing
            return regular
        }
        
        public static let compactHorizontal: CGFloat = md
        public static let regularHorizontal: CGFloat = xl
        public static let compactVertical: CGFloat = sm
        public static let regularVertical: CGFloat = lg
    }
}
