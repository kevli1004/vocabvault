import SwiftUI

// MARK: - Cream Background (replaces AnimatedGradientBackground)
// Editorial, warm, paper-like. Used as the base background for all non-card screens.

struct AnimatedGradientBackground: View {
    var body: some View {
        AppTheme.background
            .ignoresSafeArea()
    }
}

// MARK: - Shimmer Overlay (stub — removed in minimal design)

struct ShimmerOverlay: View {
    var body: some View {
        EmptyView()
    }
}
