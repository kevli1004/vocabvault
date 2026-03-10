import SwiftUI

// MARK: - Card Stack View (Tinder-style deck)

struct CardStackView: View {
    @EnvironmentObject var store: WordStore

    @State private var words: [Word] = []
    @State private var currentIndex: Int = 0
    @State private var sessionCorrect: Int = 0
    @State private var sessionIncorrect: Int = 0
    @State private var sessionTotal: Int = 0
    @State private var showSessionComplete = false
    @State private var showMasteryLevelUp = false
    @State private var masteryUpWord: Word?
    @State private var cardKey: UUID = UUID()  // force-rerender on new card
    @State private var filterMode: FilterMode = .dueAndNew

    enum FilterMode: String, CaseIterable {
        case dueAndNew  = "Study Queue"
        case all        = "All Words"
        case favorites  = "Favorites"
    }

    // MARK: - Computed

    private var currentWord: Word? {
        guard currentIndex < words.count else { return nil }
        return words[currentIndex]
    }

    private var nextWord: Word? {
        guard currentIndex + 1 < words.count else { return nil }
        return words[currentIndex + 1]
    }

    private var progress: Double {
        guard !words.isEmpty else { return 0 }
        return Double(currentIndex) / Double(words.count)
    }

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            if showSessionComplete {
                SessionCompleteView(
                    correct: sessionCorrect,
                    incorrect: sessionIncorrect,
                    total: sessionTotal
                ) {
                    restartSession()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                mainContent
            }

            // Mastery level-up toast
            if showMasteryLevelUp, let word = masteryUpWord {
                MasteryLevelUpToast(word: word)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .onAppear { loadWords() }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Header
            headerBar

            if words.isEmpty {
                emptyState
            } else {
                // Progress
                progressSection
                    .padding(.horizontal, 28)
                    .padding(.top, 12)

                Spacer(minLength: 0)

                // Card stack
                cardStack
                    .padding(.horizontal, 20)

                Spacer(minLength: 0)

                // Bottom hints
                swipeHints
                    .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Flash Cards")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("\(words.count) words in session")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }
            Spacer()

            // Filter menu
            Menu {
                ForEach(FilterMode.allCases, id: \.self) { mode in
                    Button(mode.rawValue) {
                        filterMode = mode
                        loadWords()
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    Text(filterMode.rawValue)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(Color.white.opacity(0.12))
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Progress

    private var progressSection: some View {
        HStack(spacing: 12) {
            // Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.gradPurple1, .gradTeal1],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 6)

            // Counter
            Text("\(currentIndex)/\(words.count)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .frame(minWidth: 44, alignment: .trailing)
        }
    }

    // MARK: - Card Stack

    private var cardStack: some View {
        ZStack {
            // Next card (peeking behind, slightly smaller)
            if let next = nextWord {
                CardFrontPreview(word: next)
                    .offset(y: 18)
                    .scaleEffect(0.92)
                    .opacity(0.7)
            } else if currentIndex < words.count - 1 {
                // More cards placeholder
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .frame(maxWidth: .infinity)
                    .aspectRatio(0.72, contentMode: .fit)
                    .offset(y: 18)
                    .scaleEffect(0.92)
            }

            // Current card (on top)
            if let word = currentWord {
                FlashCardView(
                    word: word,
                    onSwipeRight: { handleSwipeRight() },
                    onSwipeLeft:  { handleSwipeLeft()  },
                    onLongPress:  { handleLongPress()  }
                )
                .id(cardKey)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .bottom)
                            .combined(with: .scale(scale: 0.85))
                            .combined(with: .opacity),
                        removal: .opacity
                    )
                )
            }
        }
    }

    // MARK: - Swipe Hints

    private var swipeHints: some View {
        HStack(spacing: 0) {
            // Left = needs practice
            HStack(spacing: 6) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.swipeLeft)
                Text("More practice")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Tap hint
            HStack(spacing: 4) {
                Image(systemName: "hand.tap")
                    .font(.system(size: 12))
                Text("Tap to flip")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundColor(.white.opacity(0.35))

            Spacer()

            // Right = know it
            HStack(spacing: 6) {
                Text("I know it")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.swipeRight)
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Text("🎉")
                .font(.system(size: 64))
                .floating()

            Text("All caught up!")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)

            Text("No words due for review right now.\nCome back later or study all words.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)

            Button("Study All Words") {
                filterMode = .all
                loadWords()
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(LinearGradient.pastelGradient(for: .teal))
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func handleSwipeRight() {
        guard let word = currentWord else { return }
        let previousMastery = word.masteryLevel
        store.markCorrect(wordId: word.id)
        sessionCorrect += 1
        sessionTotal += 1

        // Check mastery level up
        if let updated = store.word(id: word.id),
           updated.masteryLevel != previousMastery {
            masteryUpWord = updated
            withAnimation(.spring()) { showMasteryLevelUp = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showMasteryLevelUp = false }
            }
        }

        advanceCard()
    }

    private func handleSwipeLeft() {
        guard let word = currentWord else { return }
        store.markIncorrect(wordId: word.id)
        sessionIncorrect += 1
        sessionTotal += 1
        advanceCard()
    }

    private func handleLongPress() {
        guard let word = currentWord else { return }
        store.toggleFavorite(wordId: word.id)
    }

    private func advanceCard() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentIndex += 1
            cardKey = UUID()
        }

        if currentIndex >= words.count {
            withAnimation(.spring()) {
                showSessionComplete = true
            }
        }
    }

    private func loadWords() {
        currentIndex = 0
        sessionCorrect = 0
        sessionIncorrect = 0
        sessionTotal = 0
        showSessionComplete = false
        cardKey = UUID()

        switch filterMode {
        case .dueAndNew:
            words = SpacedRepetition.buildStudySession(from: store.words, limit: store.dailyGoal)
        case .all:
            words = store.words.shuffled()
        case .favorites:
            words = store.favoriteWords.shuffled()
        }
    }

    private func restartSession() {
        withAnimation(.spring()) {
            showSessionComplete = false
        }
        loadWords()
    }
}

// MARK: - Card Front Preview (next card peek)

private struct CardFrontPreview: View {
    let word: Word

    var body: some View {
        let (c1, c2) = Color.categoryGradient(word.category)
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [c1.opacity(0.6), c2.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(maxWidth: .infinity)
            .aspectRatio(0.72, contentMode: .fit)
            .overlay(
                Text(word.word)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            )
    }
}

// MARK: - Session Complete

private struct SessionCompleteView: View {
    let correct: Int
    let incorrect: Int
    let total: Int
    let onRestart: () -> Void

    @State private var showConfetti = false

    private var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    var body: some View {
        ZStack {
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }

            VStack(spacing: 28) {
                // Trophy
                Text(accuracy >= 0.8 ? "🏆" : accuracy >= 0.5 ? "⭐️" : "💪")
                    .font(.system(size: 72))
                    .floating(amplitude: 8)

                VStack(spacing: 8) {
                    Text("Session Complete!")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Text(motivationalMessage)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                }

                // Stats
                HStack(spacing: 16) {
                    ResultStat(label: "Correct", value: "\(correct)", color: .swipeRight)
                    ResultStat(label: "Practiced", value: "\(incorrect)", color: .swipeLeft)
                    ResultStat(label: "Accuracy", value: "\(Int(accuracy * 100))%", color: .gradPurple1)
                }

                // Progress ring
                ProgressRing(
                    progress: accuracy,
                    lineWidth: 10,
                    ringColor: accuracy >= 0.8 ? .gradMint1 : .gradAmber1
                )
                .frame(width: 100, height: 100)

                // CTA
                Button(action: onRestart) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Study Again")
                    }
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(LinearGradient.pastelGradient(for: .purple))
                    )
                    .shadow(color: .gradPurple2.opacity(0.5), radius: 12, x: 0, y: 6)
                }
            }
            .padding(32)
        }
        .onAppear {
            if accuracy == 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showConfetti = true
                }
            }
        }
    }

    private var motivationalMessage: String {
        if accuracy >= 0.9 { return "Outstanding! You're crushing it! 🔥" }
        if accuracy >= 0.7 { return "Great work! Keep pushing forward." }
        if accuracy >= 0.5 { return "Good effort. Practice makes perfect." }
        return "Every attempt makes you stronger. Keep going!"
    }
}

private struct ResultStat: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(width: 90)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(color.opacity(0.12))
        )
    }
}

// MARK: - Mastery Level Up Toast

private struct MasteryLevelUpToast: View {
    let word: Word

    var body: some View {
        HStack(spacing: 12) {
            Text("🎉")
                .font(.system(size: 22))
            VStack(alignment: .leading, spacing: 2) {
                Text("Level Up!")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("\(word.word) → \(word.masteryLevel.rawValue)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            MasteryBadge(level: word.masteryLevel)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                )
        )
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
