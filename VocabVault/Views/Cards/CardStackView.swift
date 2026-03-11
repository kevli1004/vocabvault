import SwiftUI

// MARK: - Card Stack View
// The practice session. Full-screen pastel cards stacked on a cream shell.

struct CardStackView: View {
    @EnvironmentObject var store: WordStore

    @State private var words: [Word] = []
    @State private var currentIndex: Int = 0
    @State private var sessionCorrect: Int = 0
    @State private var sessionIncorrect: Int = 0
    @State private var showComplete: Bool = false
    @State private var cardKey: UUID = UUID()
    @State private var filterMode: FilterMode = .dueAndNew
    @State private var showMasteryToast: Bool = false
    @State private var masteryUpWord: Word? = nil

    enum FilterMode: String, CaseIterable {
        case dueAndNew = "Study Queue"
        case all       = "All Words"
        case favorites = "Favorites"
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

    // MARK: - Body

    var body: some View {
        ZStack {
            if showComplete {
                SessionCompleteView(
                    correct: sessionCorrect,
                    incorrect: sessionIncorrect,
                    total: sessionCorrect + sessionIncorrect,
                    onRestart: restartSession
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
            } else {
                practiceContent
            }

            // Mastery level-up toast
            if showMasteryToast, let word = masteryUpWord {
                MasteryToast(word: word)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .onAppear(perform: loadWords)
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: showComplete)
    }

    // MARK: - Practice Content

    @ViewBuilder
    private var practiceContent: some View {
        if words.isEmpty {
            emptyState
        } else {
            VStack(spacing: 0) {
                // Top chrome: filter + progress
                topChrome

                // Card area (takes all remaining space)
                ZStack {
                    // Ghost card behind (next word preview)
                    if let next = nextWord {
                        nextCardPreview(word: next)
                    }

                    // Current card (full screen)
                    if let word = currentWord {
                        FlashCardView(
                            word: word,
                            cardIndex: currentIndex,
                            onSwipe: handleSwipe
                        )
                        .id(cardKey)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Top Chrome

    private var topChrome: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                // Progress counter
                Text("\(currentIndex) / \(words.count)")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(AppTheme.textSecondary)

                Spacer()

                // Filter picker
                Menu {
                    ForEach(FilterMode.allCases, id: \.self) { mode in
                        Button(mode.rawValue) {
                            filterMode = mode
                            loadWords()
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(filterMode.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Thin progress bar
            ThinProgressBar(current: currentIndex, total: words.count, height: 1.5)
                .padding(.horizontal, 24)
        }
        .background(AppTheme.background)
    }

    // MARK: - Next Card Preview

    private func nextCardPreview(word: Word) -> some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(CardPalette.color(for: word.category).opacity(0.55))
            .ignoresSafeArea()
            .scaleEffect(0.94, anchor: .bottom)
            .offset(y: 22)
            .allowsHitTesting(false)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("✦")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.textTertiary)

            VStack(spacing: 8) {
                Text("All caught up")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppTheme.text)

                Text("No words due for review.\nTry studying all words.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            Button {
                filterMode = .all
                loadWords()
            } label: {
                Text("Study All Words")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.text)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .strokeBorder(AppTheme.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background.ignoresSafeArea())
    }

    // MARK: - Swipe Handler

    private func handleSwipe(_ direction: SwipeDirection) {
        guard let word = currentWord else { return }
        let previousMastery = word.masteryLevel

        switch direction {
        case .right:
            store.markCorrect(wordId: word.id)
            sessionCorrect += 1
        case .left:
            store.markIncorrect(wordId: word.id)
            sessionIncorrect += 1
        }

        // Check mastery level-up
        if let updated = store.word(id: word.id),
           updated.masteryLevel != previousMastery {
            showMasteryLevelUpToast(for: updated)
        }

        advanceCard()
    }

    private func showMasteryLevelUpToast(for word: Word) {
        masteryUpWord = word
        withAnimation(.spring()) { showMasteryToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showMasteryToast = false }
        }
    }

    private func advanceCard() {
        let nextIdx = currentIndex + 1
        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
            currentIndex = nextIdx
            cardKey = UUID()
        }

        if nextIdx >= words.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                withAnimation(.spring()) { showComplete = true }
            }
        }
    }

    // MARK: - Load / Restart

    private func loadWords() {
        currentIndex = 0
        sessionCorrect = 0
        sessionIncorrect = 0
        showComplete = false
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
        withAnimation(.spring()) { showComplete = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { loadWords() }
    }
}

// MARK: - Session Complete View (cream editorial)

private struct SessionCompleteView: View {
    let correct: Int
    let incorrect: Int
    let total: Int
    let onRestart: () -> Void

    @State private var appear = false
    @State private var showConfetti = false

    private var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if showConfetti {
                ConfettiView().ignoresSafeArea().allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                Spacer()

                // Result emoji
                Text(resultEmoji)
                    .font(.system(size: 72))
                    .scaleEffect(appear ? 1 : 0.6)
                    .opacity(appear ? 1 : 0)
                    .padding(.bottom, 28)

                // Title
                Text(resultTitle)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(AppTheme.text)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 12)

                Text(resultSubtitle)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 10)

                // Stats
                HStack(spacing: 32) {
                    statBlock(value: "\(correct)", label: "Correct")
                    statBlock(value: "\(incorrect)", label: "Review")
                    statBlock(value: "\(Int(accuracy * 100))%", label: "Accuracy")
                }
                .padding(.top, 40)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 16)

                // Thin divider
                MinimalDivider()
                    .padding(.horizontal, 48)
                    .padding(.top, 36)
                    .opacity(appear ? 1 : 0)

                Spacer()

                // CTA
                Button(action: onRestart) {
                    Text("Study Again")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(AppTheme.border, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78)) { appear = true }
            if accuracy == 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showConfetti = true }
            }
        }
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppTheme.text)
                .monospacedDigit()
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
                .kerning(0.8)
        }
    }

    private var resultEmoji: String {
        if accuracy == 1.0 { return "🏆" }
        if accuracy >= 0.8  { return "⭐️" }
        if accuracy >= 0.5  { return "💪" }
        return "📚"
    }

    private var resultTitle: String {
        if accuracy == 1.0 { return "Perfect." }
        if accuracy >= 0.8  { return "Well done." }
        if accuracy >= 0.5  { return "Good effort." }
        return "Keep at it."
    }

    private var resultSubtitle: String {
        if accuracy == 1.0 { return "A perfect session. Remarkable." }
        if accuracy >= 0.8  { return "Solid work. The words are sticking." }
        if accuracy >= 0.5  { return "Every session builds the foundation." }
        return "The difficult words are the most valuable."
    }
}

// MARK: - Mastery Toast

private struct MasteryToast: View {
    let word: Word

    var body: some View {
        HStack(spacing: 12) {
            Text("✦")
                .font(.system(size: 18))
                .foregroundColor(AppTheme.textSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Level up")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(AppTheme.textTertiary)
                    .kerning(0.8)
                Text("\(word.word) → \(word.masteryLevel.rawValue)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.text)
            }

            Spacer()

            MasteryBadge(level: word.masteryLevel)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.top, 64)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
