import SwiftUI

// MARK: - Swipe Direction

enum SwipeDirection {
    case left, right
}

// MARK: - Comparable Clamp

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Flash Card View
// Pure minimalism. Full-screen color. One word. Tap to reveal. Swipe to progress.

struct FlashCardView: View {
    let word: Word
    let cardIndex: Int
    let onSwipe: (SwipeDirection) -> Void

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var revealed: Bool = false

    private var cardColor: Color { CardPalette.color(for: word.category) }

    private var dragProgress: Double { min(Double(abs(offset.width)) / 120.0, 1.0) }
    private var dragDirection: SwipeDirection? {
        if offset.width > 30  { return .right }
        if offset.width < -30 { return .left  }
        return nil
    }

    var body: some View {
        ZStack {
            // Full-bleed card color
            cardColor.ignoresSafeArea()

            // Subtle swipe tint
            if let dir = dragDirection {
                (dir == .right ? Color.swipeRight : Color.swipeLeft)
                    .opacity(dragProgress * 0.15)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // The word — centered, massive
            Text(word.word)
                .font(.system(size: 56, weight: .bold, design: .default))
                .foregroundColor(CardPalette.cardText)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)

            // Detail panel (slides up on tap)
            if revealed {
                DetailPanel(word: word, cardColor: cardColor, onDismiss: {
                    withAnimation(.easeInOut(duration: 0.28)) { revealed = false }
                })
                .transition(.slideUpFade)
            }
        }
        .offset(offset)
        .rotationEffect(.degrees(rotation), anchor: .bottom)
        .gesture(swipeGesture)
        .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.72), value: offset)
        .contentShape(Rectangle())
        .onTapGesture {
            if abs(offset.width) < 5 {
                withAnimation(.easeInOut(duration: 0.28)) { revealed.toggle() }
            }
        }
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                if revealed {
                    withAnimation(.easeInOut(duration: 0.2)) { revealed = false }
                }
                offset = value.translation
                rotation = (Double(value.translation.width) / 20.0).clamped(to: -12.0...12.0)
            }
            .onEnded { value in
                let threshold: CGFloat = 100
                let velocity = value.predictedEndTranslation.width

                if value.translation.width > threshold || velocity > 250 {
                    launchCard(direction: .right)
                } else if value.translation.width < -threshold || velocity < -250 {
                    launchCard(direction: .left)
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                        offset = .zero
                        rotation = 0
                    }
                }
            }
    }

    private func launchCard(direction: SwipeDirection) {
        let targetX: CGFloat = direction == .right ? 700 : -700
        withAnimation(.easeIn(duration: 0.28)) {
            offset = CGSize(width: targetX, height: offset.height - 20)
            rotation = direction == .right ? 20 : -20
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            onSwipe(direction)
        }
    }
}

// MARK: - Detail Panel (slides up on tap — no chrome, no handle)

private struct DetailPanel: View {
    let word: Word
    let cardColor: Color
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Category
                        Text(word.category.rawValue.lowercased())
                            .font(.system(size: 13, weight: .medium))
                            .italic()
                            .foregroundColor(CardPalette.cardText.opacity(0.45))
                            .padding(.top, 28)

                        // Definition
                        Text(word.definition)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(CardPalette.cardText)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)

                        Rectangle()
                            .fill(CardPalette.cardText.opacity(0.10))
                            .frame(height: 1)

                        // Example
                        Text(""\(word.exampleSentence)"")
                            .font(.system(size: 15, weight: .regular))
                            .italic()
                            .foregroundColor(CardPalette.cardText.opacity(0.70))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)

                        // Synonyms
                        if !word.synonyms.isEmpty {
                            Rectangle()
                                .fill(CardPalette.cardText.opacity(0.10))
                                .frame(height: 1)

                            HStack(spacing: 8) {
                                ForEach(word.synonyms, id: \.self) { syn in
                                    Text(syn)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(CardPalette.cardText.opacity(0.70))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.30))
                                        )
                                }
                            }
                        }

                        // Mnemonic
                        Rectangle()
                            .fill(CardPalette.cardText.opacity(0.10))
                            .frame(height: 1)

                        Text(word.mnemonic)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(CardPalette.cardText.opacity(0.65))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 50)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(cardColor)
            )
            .onTapGesture { } // Prevent tap-through
        }
        .ignoresSafeArea(edges: .bottom)
        .onTapGesture { onDismiss() }
    }
}
