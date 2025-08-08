import SwiftUI

@main
struct DynamicFormsApp: App {
    
    init() {
        setupDependencies()
    }
    
    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
        }
    }
    
    private func setupDependencies() {
        // Initialize dependency injection container
        _ = DIContainer.shared
    }
}

// MARK: - AppCoordinator Wrapper
/// SwiftUI wrapper for AppCoordinator to satisfy value type requirement
struct AppCoordinatorView: View {
    @StateObject private var coordinator = AppCoordinator()
    
    var body: some View {
        coordinator.body
    }
}