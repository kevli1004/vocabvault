import SwiftUI

// MARK: - Flash Card View (single card, front + back)

struct FlashCardView: View {
    let word: Word
    var onSwipeRight: () -> Void = {}  // "I know this"
    var onSwipeLeft: () -> Void  = {}  // "Need more practice"
    var onLongPress: () -> Void  = {}  // bookmark

    @State private var dragOffset: CGSize = .zero
    @State private var isFlipped = false
    @State private var rotationDegrees: Double = 0
    @State private var showingRightOverlay = false
    @State private var showingLeftOverlay  = false
    @State private var cardOpacity: Double = 1
    @State private var isLongPressActive = false

    // Derived
    private var swipeProgress: Double { Double(dragOffset.width) / 140 }
    private var isShowingFront: Bool { !isFlipped }

    var body: some View {
        ZStack {
            // The Card itself
            cardContent
                .rotation3DEffect(
                    .degrees(rotationDegrees),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.4
                )
                .offset(dragOffset)
                .rotationEffect(.degrees(Double(dragOffset.width) / 22))
                .scaleEffect(isLongPressActive ? 0.97 : 1.0)
                .opacity(cardOpacity)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isLongPressActive)
                .gesture(
                    SimultaneousGesture(
                        dragGesture,
                        longPressGesture
                    )
                )
                .onTapGesture { flipCard() }

            // RIGHT overlay: "I Know This"
            SwipeOverlay(
                text: "I know this!",
                icon: "checkmark.circle.fill",
                color: .swipeRight,
                side: .right
            )
            .opacity(max(0, swipeProgress))

            // LEFT overlay: "More Practice"
            SwipeOverlay(
                text: "Keep practicing",
                icon: "arrow.clockwise",
                color: .swipeLeft,
                side: .left
            )
            .opacity(max(0, -swipeProgress))

            // Bookmark overlay on long press
            if isLongPressActive {
                VStack(spacing: 8) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.swipeFav)
                    Text("Bookmarked!")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.swipeFav)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Card Content

    @ViewBuilder
    private var cardContent: some View {
        if !isFlipped || rotationDegrees <= 90 {
            CardFront(word: word)
        } else {
            CardBack(word: word)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                // Only horizontal drag
                let x = value.translation.width
                let y = value.translation.height
                guard abs(x) > abs(y) * 0.5 else { return }
                withAnimation(.interactiveSpring()) {
                    dragOffset = CGSize(width: x, height: y * 0.15)
                }
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.width
                let threshold: CGFloat = 110

                if velocity > threshold || dragOffset.width > threshold {
                    fireSwipe(direction: .right)
                } else if velocity < -threshold || dragOffset.width < -threshold {
                    fireSwipe(direction: .left)
                } else {
                    // Snap back
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.6)
            .onEnded { _ in
                withAnimation(.spring()) {
                    isLongPressActive = true
                }
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                onLongPress()

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation { isLongPressActive = false }
                }
            }
    }

    // MARK: - Swipe Actions

    private enum SwipeDirection { case left, right }

    private func fireSwipe(direction: SwipeDirection) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        let flyX: CGFloat = direction == .right ? 600 : -600

        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            dragOffset = CGSize(width: flyX, height: dragOffset.height * 2)
            cardOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if direction == .right {
                onSwipeRight()
            } else {
                onSwipeLeft()
            }
        }
    }

    // MARK: - Flip

    private func flipCard() {
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred()

        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            rotationDegrees += 180
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isFlipped.toggle()
        }
    }
}

// MARK: - Card Front

private struct CardFront: View {
    let word: Word
    @State private var appear = false

    var body: some View {
        let (c1, c2) = Color.categoryGradient(word.category)

        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [c1, c2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Subtle shimmer overlay
            ShimmerOverlay()
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            // Border
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1.5)

            // Content
            VStack(spacing: 0) {
                // Top row: category + difficulty
                HStack {
                    CategoryBadge(category: word.category)
                    Spacer()
                    DifficultyDots(difficulty: word.difficulty)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)

                Spacer()

                // Word
                VStack(spacing: 8) {
                    Text(word.word)
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .scaleEffect(appear ? 1 : 0.85)
                        .opacity(appear ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appear)
                }

                Spacer()

                // Bottom hint
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 13))
                    Text("Tap to reveal")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.bottom, 28)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.72, contentMode: .fit)
        .shadow(color: c2.opacity(0.5), radius: 24, x: 0, y: 12)
        .onAppear { appear = true }
        .onDisappear { appear = false }
    }
}

// MARK: - Card Back

private struct CardBack: View {
    let word: Word
    @State private var appear = false

    var body: some View {
        ZStack {
            // Dark glass background
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.08, blue: 0.20),
                            Color(red: 0.06, green: 0.05, blue: 0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Accent top strip
            let (c1, _) = Color.categoryGradient(word.category)
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(c1.opacity(0.08))

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {

                    // Word title (small on back)
                    HStack {
                        Text(word.word)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        CategoryBadge(category: word.category)
                    }
                    .padding(.top, 4)

                    Divider().background(Color.white.opacity(0.15))

                    // Definition
                    BackSection(
                        icon: "text.alignleft",
                        title: "Definition",
                        content: word.definition,
                        color: c1
                    )

                    // Example sentence
                    BackSection(
                        icon: "quote.bubble.fill",
                        title: "Example",
                        content: word.exampleSentence,
                        color: Color.gradTeal1
                    )

                    // Synonyms
                    VStack(alignment: .leading, spacing: 6) {
                        BackSectionHeader(icon: "arrow.triangle.2.circlepath", title: "Synonyms", color: Color.gradMint1)
                        HStack(spacing: 8) {
                            ForEach(word.synonyms, id: \.self) { syn in
                                Text(syn)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule().fill(Color.white.opacity(0.12))
                                    )
                            }
                        }
                    }

                    // Origin
                    BackSection(
                        icon: "globe.europe.africa.fill",
                        title: "Origin",
                        content: word.etymology,
                        color: Color.gradAmber1
                    )

                    // Mnemonic
                    BackSection(
                        icon: "lightbulb.fill",
                        title: "Remember it",
                        content: word.mnemonic,
                        color: Color.gradRose1
                    )
                }
                .padding(24)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 10)
                .animation(.easeOut(duration: 0.3), value: appear)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.72, contentMode: .fit)
        .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 12)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                appear = true
            }
        }
        .onDisappear { appear = false }
    }
}

// MARK: - Back Section Helpers

private struct BackSectionHeader: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(color.opacity(0.8))
                .kerning(1.2)
        }
    }
}

private struct BackSection: View {
    let icon: String
    let title: String
    let content: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            BackSectionHeader(icon: icon, title: title, color: color)
            Text(content)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Swipe Overlay

private struct SwipeOverlay: View {
    let text: String
    let icon: String
    let color: Color
    enum Side { case left, right }
    let side: Side

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(color.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(color.opacity(0.4), lineWidth: 2)
                )
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: side == .right ? .topLeading : .topTrailing)
        .padding(side == .right ? .leading : .trailing, 30)
        .padding(.top, 60)
        .allowsHitTesting(false)
    }
}
