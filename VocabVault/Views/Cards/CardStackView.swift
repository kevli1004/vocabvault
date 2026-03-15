import SwiftUI

// MARK: - Card Stack View
// Nothing but the card. Full screen. No overlays.

struct CardStackView: View {
    @EnvironmentObject var store: WordStore

    @State private var words: [Word] = []
    @State private var currentIndex: Int = 0
    @State private var sessionCorrect: Int = 0
    @State private var sessionIncorrect: Int = 0
    @State private var showComplete: Bool = false
    @State private var cardKey: UUID = UUID()

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
            ZStack {
                // Ghost of next card
                if let next = nextWord {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(CardPalette.color(for: next.category).opacity(0.55))
                        .ignoresSafeArea()
                        .scaleEffect(0.94, anchor: .bottom)
                        .offset(y: 22)
                        .allowsHitTesting(false)
                }

                // Current card — full screen, nothing on top
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
            .ignoresSafeArea()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("All caught up")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.text)

            Text("No words due for review.")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(AppTheme.textSecondary)

            Button {
                words = store.words.shuffled()
                currentIndex = 0
                cardKey = UUID()
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

        switch direction {
        case .right:
            store.markCorrect(wordId: word.id)
            sessionCorrect += 1
        case .left:
            store.markIncorrect(wordId: word.id)
            sessionIncorrect += 1
        }

        advanceCard()
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
        words = SpacedRepetition.buildStudySession(from: store.words, limit: store.dailyGoal)
    }

    private func restartSession() {
        withAnimation(.spring()) { showComplete = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { loadWords() }
    }
}

// MARK: - Session Complete View (minimal — accuracy + restart)

private struct SessionCompleteView: View {
    let correct: Int
    let incorrect: Int
    let total: Int
    let onRestart: () -> Void

    @State private var appear = false

    private var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Accuracy — the hero number
                Text("\(Int(accuracy * 100))%")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(AppTheme.text)
                    .monospacedDigit()
                    .opacity(appear ? 1 : 0)
                    .scaleEffect(appear ? 1 : 0.8)

                Text(resultTitle)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 12)
                    .opacity(appear ? 1 : 0)

                Spacer()

                // Study Again
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
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78)) { appear = true }
        }
    }

    private var resultTitle: String {
        if accuracy == 1.0 { return "Perfect." }
        if accuracy >= 0.8  { return "Well done." }
        if accuracy >= 0.5  { return "Good effort." }
        return "Keep at it."
    }
}
