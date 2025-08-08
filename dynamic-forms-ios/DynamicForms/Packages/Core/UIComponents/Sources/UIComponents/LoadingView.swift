import SwiftUI
import DesignSystem

/// Loading view component with consistent styling across the app
/// Following Single Responsibility Principle for loading states
public struct LoadingView: View {
    
    // MARK: - Properties
    private let message: String?
    private let style: LoadingStyle
    private let size: LoadingSize
    
    // MARK: - Loading Styles
    public enum LoadingStyle {
        case spinner
        case dots
        case skeleton
    }
    
    public enum LoadingSize {
        case small
        case medium
        case large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 48
            case .large: return 72
            }
        }
    }
    
    // MARK: - Initialization
    public init(
        message: String? = nil,
        style: LoadingStyle = .spinner,
        size: LoadingSize = .medium
    ) {
        self.message = message
        self.style = style
        self.size = size
    }
    
    // MARK: - Body
    public var body: some View {
        VStack(spacing: DFSpacing.md) {
            loadingIndicator
            
            if let message = message {
                Text(message)
                    .font(DFTypography.bodyMedium)
                    .foregroundColor(DFColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(DFSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DFColors.background)
    }
    
    // MARK: - Loading Indicators
    @ViewBuilder
    private var loadingIndicator: some View {
        switch style {
        case .spinner:
            spinnerView
        case .dots:
            dotsView
        case .skeleton:
            skeletonView
        }
    }
    
    private var spinnerView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: DFColors.primary))
            .scaleEffect(scaleForSize)
            .frame(width: size.dimension, height: size.dimension)
    }
    
    private var dotsView: some View {
        HStack(spacing: DFSpacing.xs) {
            ForEach(0..<3, id: \.self) { index in
                DotView(delay: Double(index) * 0.2)
            }
        }
    }
    
    private var skeletonView: some View {
        VStack(spacing: DFSpacing.sm) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonLine()
            }
        }
        .frame(maxWidth: 200)
    }
    
    private var scaleForSize: CGFloat {
        switch size {
        case .small: return 0.8
        case .medium: return 1.0
        case .large: return 1.5
        }
    }
}

// MARK: - Dot Animation View
private struct DotView: View {
    @State private var isAnimating = false
    private let delay: Double
    
    init(delay: Double) {
        self.delay = delay
    }
    
    var body: some View {
        Circle()
            .fill(DFColors.primary)
            .frame(width: 8, height: 8)
            .opacity(isAnimating ? 0.3 : 1.0)
            .animation(
                Animation.easeInOut(duration: 0.6)
                    .repeatForever()
                    .delay(delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Skeleton Line View
private struct SkeletonLine: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    colors: [
                        DFColors.surfaceVariant.opacity(0.3),
                        DFColors.surfaceVariant.opacity(0.7),
                        DFColors.surfaceVariant.opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 16)
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .black, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(70))
                    .offset(x: isAnimating ? 200 : -200)
            )
            .animation(
                Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Fullscreen Loading Overlay
public struct LoadingOverlay: View {
    private let message: String?
    private let isVisible: Bool
    
    public init(message: String? = nil, isVisible: Bool = true) {
        self.message = message
        self.isVisible = isVisible
    }
    
    public var body: some View {
        if isVisible {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                // Loading content
                VStack(spacing: DFSpacing.lg) {
                    LoadingView(message: message, style: .spinner, size: .large)
                }
                .padding(DFSpacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                        .fill(DFColors.surface)
                        .shadow(
                            color: DFColors.shadow.opacity(0.2),
                            radius: DesignSystem.Elevation.high,
                            x: 0,
                            y: 4
                        )
                )
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: DesignSystem.Animation.normal), value: isVisible)
        }
    }
}

// MARK: - Loading Button State
public struct LoadingButton: View {
    private let title: String
    private let isLoading: Bool
    private let isEnabled: Bool
    private let action: () -> Void
    
    public init(
        title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    public var body: some View {
        PrimaryButton(
            title: title,
            isEnabled: isEnabled && !isLoading,
            isLoading: isLoading,
            action: action
        )
    }
}

// MARK: - Inline Loading Indicator
public struct InlineLoadingView: View {
    private let size: LoadingView.LoadingSize
    
    public init(size: LoadingView.LoadingSize = .small) {
        self.size = size
    }
    
    public var body: some View {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DFColors.primary))
                .scaleEffect(size == .small ? 0.6 : 0.8)
            
            Text("Loading...")
                .font(DFTypography.labelMedium)
                .foregroundColor(DFColors.onSurfaceVariant)
        }
        .padding(.vertical, DFSpacing.xs)
    }
}

// MARK: - Loading State Modifier
public extension View {
    
    /// Show loading overlay when condition is true
    func loadingOverlay(_ isLoading: Bool, message: String? = nil) -> some View {
        ZStack {
            self
            LoadingOverlay(message: message, isVisible: isLoading)
        }
    }
    
    /// Show inline loading when condition is true
    func inlineLoading(_ isLoading: Bool, size: LoadingView.LoadingSize = .small) -> some View {
        Group {
            if isLoading {
                InlineLoadingView(size: size)
            } else {
                self
            }
        }
    }
}

// MARK: - Previews
#if DEBUG
struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DFSpacing.xl) {
            LoadingView(message: "Loading forms...", style: .spinner, size: .small)
            LoadingView(message: "Processing...", style: .spinner, size: .medium)
            LoadingView(message: "Saving data...", style: .spinner, size: .large)
            
            LoadingView(message: "Please wait...", style: .dots)
            LoadingView(style: .skeleton)
            
            InlineLoadingView()
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Loading States")
    }
}
#endif