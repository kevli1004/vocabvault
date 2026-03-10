import SwiftUI

// MARK: - View Animation Extensions

extension View {

    /// Shimmer loading effect
    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }

    /// Scale bounce on appear
    func bouncyAppear(delay: Double = 0) -> some View {
        self.modifier(BouncyAppearModifier(delay: delay))
    }

    /// Subtle float animation (up/down)
    func floating(amplitude: CGFloat = 6, duration: Double = 2.5) -> some View {
        self.modifier(FloatingModifier(amplitude: amplitude, duration: duration))
    }

    /// Glow effect
    func glow(color: Color, radius: CGFloat = 12) -> some View {
        self.shadow(color: color.opacity(0.6), radius: radius / 2)
            .shadow(color: color.opacity(0.3), radius: radius)
    }

    /// Card press scale
    func pressScaleFeedback(scale: CGFloat = 0.96) -> some View {
        self.modifier(PressScaleModifier(pressedScale: scale))
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay(
                    GeometryReader { geo in
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .white.opacity(0.4), location: 0.3),
                                .init(color: .white.opacity(0.7), location: 0.5),
                                .init(color: .white.opacity(0.4), location: 0.7),
                                .init(color: .clear, location: 1)
                            ]),
                            startPoint: .init(x: phase - 1, y: 0.5),
                            endPoint:   .init(x: phase,     y: 0.5)
                        )
                        .frame(width: geo.size.width * 3)
                        .offset(x: -geo.size.width + phase * geo.size.width * 2)
                    }
                    .clipped()
                    .allowsHitTesting(false)
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                        phase = 1.5
                    }
                }
        } else {
            content
        }
    }
}

// MARK: - Bouncy Appear Modifier

struct BouncyAppearModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(
                    .spring(response: 0.5, dampingFraction: 0.65, blendDuration: 0)
                    .delay(delay)
                ) {
                    appeared = true
                }
            }
    }
}

// MARK: - Floating Modifier

struct FloatingModifier: ViewModifier {
    let amplitude: CGFloat
    let duration: Double
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = amplitude
                }
            }
    }
}

// MARK: - Press Scale Modifier

struct PressScaleModifier: ViewModifier {
    let pressedScale: CGFloat
    @State private var pressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? pressedScale : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pressed)
            .onTapGesture { }  // absorb just for animation—real tap handled by parent
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressed = true }
                    .onEnded   { _ in pressed = false }
            )
    }
}
