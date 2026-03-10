import SwiftUI

// MARK: - Animated Pastel Background

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false

    let palettes: [GradientPalette] = [.purple, .teal, .coral, .rose]
    @State private var currentPaletteIndex = 0

    var body: some View {
        TimelineView(.animation) { _ in
            ZStack {
                // Base dark layer
                Color.bgDark1.ignoresSafeArea()

                // Animated blobs
                GradientBlob(
                    color: blobColor(0),
                    position: CGPoint(
                        x: animateGradient ? 0.65 : 0.35,
                        y: animateGradient ? 0.25 : 0.45
                    ),
                    size: 400
                )

                GradientBlob(
                    color: blobColor(1),
                    position: CGPoint(
                        x: animateGradient ? 0.25 : 0.70,
                        y: animateGradient ? 0.65 : 0.30
                    ),
                    size: 350
                )

                GradientBlob(
                    color: blobColor(2),
                    position: CGPoint(
                        x: animateGradient ? 0.80 : 0.15,
                        y: animateGradient ? 0.80 : 0.55
                    ),
                    size: 300
                )
            }
            .blur(radius: 60)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .easeInOut(duration: 6)
                .repeatForever(autoreverses: true)
            ) {
                animateGradient = true
            }
        }
    }

    private func blobColor(_ index: Int) -> Color {
        let palette = palettes[(currentPaletteIndex + index) % palettes.count]
        return Color.gradientColors(for: palette).0
    }
}

// MARK: - Gradient Blob

private struct GradientBlob: View {
    let color: Color
    let position: CGPoint
    let size: CGFloat

    var body: some View {
        GeometryReader { geo in
            Circle()
                .fill(color.opacity(0.45))
                .frame(width: size, height: size)
                .position(
                    x: position.x * geo.size.width,
                    y: position.y * geo.size.height
                )
        }
    }
}

// MARK: - Card Gradient

struct CardGradient: View {
    let palette: GradientPalette
    var cornerRadius: CGFloat = 28

    var body: some View {
        let (c1, c2) = Color.gradientColors(for: palette)
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [c1, c2],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

// MARK: - Pastel Gradient View

struct PastelGradientView: View {
    let palette: GradientPalette
    var opacity: Double = 1.0

    var body: some View {
        let (c1, c2) = Color.gradientColors(for: palette)
        LinearGradient(
            colors: [c1.opacity(opacity), c2.opacity(opacity)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Subtle Shimmer Overlay

struct ShimmerOverlay: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .white.opacity(0.12), location: 0.45),
                    .init(color: .white.opacity(0.20), location: 0.50),
                    .init(color: .white.opacity(0.12), location: 0.55),
                    .init(color: .clear, location: 1)
                ]),
                startPoint: .init(x: phase - 1, y: 0),
                endPoint:   .init(x: phase,     y: 1)
            )
            .frame(width: geo.size.width * 3)
            .offset(x: phase * geo.size.width * 2 - geo.size.width)
        }
        .clipped()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                phase = 1.5
            }
        }
    }
}
