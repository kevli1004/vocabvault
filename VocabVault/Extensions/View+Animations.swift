import SwiftUI

// MARK: - View Animations (minimal, editorial)

extension View {

    /// Subtle fade-in with optional upward offset. Clean, no spring bounce.
    func fadeIn(delay: Double = 0, offset: CGFloat = 12) -> some View {
        modifier(FadeInModifier(delay: delay, offset: offset))
    }

    /// Placeholder: floating removed. Returns self unchanged.
    func floating(amplitude: CGFloat = 6, duration: Double = 2.5) -> some View {
        self
    }

    /// Light press effect for buttons.
    func pressEffect() -> some View {
        modifier(PressEffectModifier())
    }
}

// MARK: - Fade In Modifier

private struct FadeInModifier: ViewModifier {
    let delay: Double
    let offset: CGFloat
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : offset)
            .onAppear {
                withAnimation(.easeOut(duration: 0.38).delay(delay)) {
                    visible = true
                }
            }
    }
}

// MARK: - Press Effect Modifier

private struct PressEffectModifier: ViewModifier {
    @State private var pressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.12), value: pressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressed = true }
                    .onEnded   { _ in pressed = false }
            )
    }
}

// MARK: - Transition helpers

extension AnyTransition {
    static let slideUpFade: AnyTransition =
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal:   .move(edge: .bottom).combined(with: .opacity)
        )

    static let crossDissolve: AnyTransition = .opacity
}
