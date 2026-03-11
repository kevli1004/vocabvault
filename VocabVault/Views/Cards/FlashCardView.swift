import SwiftUI

// MARK: - Flash Card View
// Full-screen solid pastel background per word. Word is the hero.
// Tap to reveal definition panel. Swipe left/right for spaced repetition.

struct FlashCardView: View {
    let word: Word
    let cardIndex: Int
    let onSwipe: (SwipeDirection) -> Void

    @EnvironmentObject var store: WordStore
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var revealed: Bool = false
    @State private var showDetail: Bool = false

    // Swipe feedback
    @State private var swipeHint: SwipeDirection? = nil

    private var cardColor: Color { CardPalette.color(for: word.category) }

    // How far dragged (0–1) and direction
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

            // Swipe direction tint overlay
            if let dir = dragDirection {
                (dir == .right ? Color.swipeRight : Color.swipeLeft)
                    .opacity(dragProgress * 0.18)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                // Top: category + mastery
                cardTopBar

                Spacer()

                // Main word content
                wordContent

                Spacer()

                // Bottom action row
                cardBottomActions
            }
            .padding(.horizontal, 32)
            .padding(.top, 96) // Clear floating chrome overlay
            .padding(.bottom, 100) // Clear tab bar

            // Swipe hint labels
            swipeHints

            // Detail panel overlay (tap to reveal)
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
            // Only toggle detail if not dragging
            if abs(offset.width) < 5 {
                withAnimation(.easeInOut(duration: 0.28)) { revealed.toggle() }
            }
        }
    }

    // MARK: - Top Bar

    private var cardTopBar: some View {
        HStack {
            CardCategoryBadge(category: word.category)
            Spacer()
            DifficultyDots(difficulty: word.difficulty)
                .opacity(0.7)
        }
    }

    // MARK: - Word Content (center hero)

    private var wordContent: some View {
        VStack(spacing: 20) {
            // The word itself — massive, bold, centered
            Text(word.word)
                .font(.system(size: 56, weight: .bold, design: .default))
                .foregroundColor(CardPalette.cardText)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)

            // Category pill (serves as visual breath between word and hint)
            HStack(spacing: 6) {
                Text(word.category.rawValue)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(CardPalette.cardText.opacity(0.55))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.30))
            )

            if !revealed {
                // Tap hint
                Text("tap to reveal")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(CardPalette.cardText.opacity(0.35))
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Bottom Action Row

    private var cardBottomActions: some View {
        HStack(spacing: 40) {
            ActionIcon(systemName: "info.circle") {
                showDetail = true
            }

            ActionIcon(
                systemName: word.isFavorite ? "heart.fill" : "heart",
                tint: word.isFavorite ? CardPalette.dustyRose : CardPalette.cardText.opacity(0.55)
            ) {
                store.toggleFavorite(wordId: word.id)
            }

            ActionIcon(systemName: "square.and.arrow.up") {
                shareWord()
            }
        }
        .sheet(isPresented: $showDetail) {
            CardDetailView(word: word)
                .environmentObject(store)
        }
    }

    // MARK: - Swipe Hints

    private var swipeHints: some View {
        HStack {
            // Left: "Hard" hint
            swipeLabel("Hard", systemImage: "xmark", color: .swipeLeft)
                .opacity(offset.width < -20 ? (Double(-offset.width - 20) / 60.0).clamped(to: 0.0...1.0) : 0)

            Spacer()

            // Right: "Got it" hint
            swipeLabel("Got it", systemImage: "checkmark", color: .swipeRight)
                .opacity(offset.width > 20 ? (Double(offset.width - 20) / 60.0).clamped(to: 0.0...1.0) : 0)
        }
        .padding(.horizontal, 36)
        .padding(.top, 60)
        .frame(maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
    }

    private func swipeLabel(_ text: String, systemImage: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
            Text(text)
                .font(.system(size: 15, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
                .overlay(Capsule().strokeBorder(color.opacity(0.4), lineWidth: 1))
        )
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                // Dismiss detail panel if open
                if revealed {
                    withAnimation(.easeInOut(duration: 0.2)) { revealed = false }
                }
                let translation = value.translation
                offset = translation
                rotation = (Double(translation.width) / 20.0).clamped(to: -12.0...12.0)
            }
            .onEnded { value in
                let threshold: CGFloat = 100
                let velocity = value.predictedEndTranslation.width

                if value.translation.width > threshold || velocity > 250 {
                    // Swipe right → got it (correct)
                    launchCard(direction: .right)
                } else if value.translation.width < -threshold || velocity < -250 {
                    // Swipe left → hard (incorrect)
                    launchCard(direction: .left)
                } else {
                    // Snap back
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

    // MARK: - Share

    private func shareWord() {
        let text = "\(word.word) — \(word.definition)"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }
}

// MARK: - Action Icon Button

private struct ActionIcon: View {
    let systemName: String
    var tint: Color = CardPalette.cardText.opacity(0.55)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .light))
                .foregroundColor(tint)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Detail Panel (slides up on tap)

private struct DetailPanel: View {
    let word: Word
    let cardColor: Color
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 2)
                    .fill(CardPalette.cardText.opacity(0.20))
                    .frame(width: 36, height: 3)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)
                    .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Part of speech + definition
                        VStack(alignment: .leading, spacing: 8) {
                            Text(word.category.rawValue.lowercased())
                                .font(.system(size: 13, weight: .medium, design: .default))
                                .italic()
                                .foregroundColor(CardPalette.cardText.opacity(0.45))

                            Text(word.definition)
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(CardPalette.cardText)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Rectangle()
                            .fill(CardPalette.cardText.opacity(0.12))
                            .frame(height: 1)

                        // Example sentence
                        VStack(alignment: .leading, spacing: 6) {
                            Text("EXAMPLE")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(CardPalette.cardText.opacity(0.4))
                                .kerning(1.2)

                            Text(""\(word.exampleSentence)"")
                                .font(.system(size: 15, weight: .regular))
                                .italic()
                                .foregroundColor(CardPalette.cardText.opacity(0.75))
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Synonyms
                        if !word.synonyms.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SYNONYMS")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(CardPalette.cardText.opacity(0.4))
                                    .kerning(1.2)

                                FlexWrap(items: word.synonyms) { syn in
                                    Text(syn)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(CardPalette.cardText.opacity(0.75))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.40))
                                        )
                                }
                            }
                        }

                        // Mnemonic
                        VStack(alignment: .leading, spacing: 6) {
                            Text("MEMORY AID")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(CardPalette.cardText.opacity(0.4))
                                .kerning(1.2)

                            Text(word.mnemonic)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(CardPalette.cardText.opacity(0.70))
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 50)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(cardColor.opacity(0.88))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.4))
                    )
            )
            .onTapGesture { } // Prevent tap-through
        }
        .ignoresSafeArea(edges: .bottom)
        .onTapGesture { onDismiss() } // Tap outside panel to dismiss... actually this is on the overlay
    }
}

// MARK: - Flex Wrap (for synonym chips)

private struct FlexWrap<Item: Hashable, ItemView: View>: View {
    let items: [Item]
    let content: (Item) -> ItemView

    @State private var totalHeight = CGFloat.zero

    var body: some View {
        GeometryReader { geo in
            self.generateContent(in: geo)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geo: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        var lastHeight = CGFloat.zero
        let spacing: CGFloat = 8

        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .padding(1)
                    .alignmentGuide(.leading) { d in
                        if abs(width - d.width) > geo.size.width {
                            width = 0
                            height -= lastHeight + spacing
                        }
                        let result = width
                        if item == items.last { width = 0 } else { width -= d.width + spacing }
                        return result
                    }
                    .alignmentGuide(.top) { d in
                        let result = height
                        lastHeight = d.height
                        return result
                    }
            }
        }
        .background(GeometryReader { geo2 in
            Color.clear.preference(key: HeightKey.self, value: geo2.size.height)
        })
        .onPreferenceChange(HeightKey.self) { totalHeight = $0 }
    }
}

private struct HeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Comparable Clamp

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Swipe Direction

enum SwipeDirection {
    case left, right
}
