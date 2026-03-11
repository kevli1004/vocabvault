import SwiftUI

// MARK: - Quiz Results View (cream, editorial)

struct QuizResultsView: View {
    let session: QuizEngine.QuizSession
    let allWords: [Word]
    let onPlayAgain: () -> Void

    @State private var appear = false
    @State private var showConfetti = false
    @State private var showWrongAnswers = false

    private var accuracy: Double { session.accuracy }
    private var isPerfect: Bool { session.isPerfectScore }

    private var wrongWords: [Word] {
        let ids = QuizEngine.wrongAnswerIds(from: session)
        return allWords.filter { ids.contains($0.id) }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if showConfetti {
                ConfettiView().ignoresSafeArea().allowsHitTesting(false)
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero result
                    resultHero
                        .padding(.horizontal, 28)
                        .padding(.top, 64)
                        .padding(.bottom, 36)

                    MinimalDivider()

                    // Score + stats
                    statsSection
                        .padding(.horizontal, 28)
                        .padding(.top, 28)
                        .padding(.bottom, 28)

                    MinimalDivider()

                    // Time
                    timeRow
                        .padding(.horizontal, 28)
                        .padding(.vertical, 20)

                    MinimalDivider()

                    // Wrong answers
                    if !wrongWords.isEmpty {
                        wrongAnswersSection
                            .padding(.top, 24)
                    }

                    // CTA
                    ctaSection
                        .padding(.horizontal, 28)
                        .padding(.top, 36)
                        .padding(.bottom, 60)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) { appear = true }
            if isPerfect {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { showConfetti = true }
            }
        }
    }

    // MARK: - Hero

    private var resultHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(resultEmoji)
                .font(.system(size: 52))
                .scaleEffect(appear ? 1 : 0.7)
                .opacity(appear ? 1 : 0)

            Text(resultTitle)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(AppTheme.text)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 10)

            Text(resultSubtitle)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(3)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 8)
        }
        .animation(.easeOut(duration: 0.45), value: appear)
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 0) {
            resultStat(value: "\(Int(accuracy * 100))%", label: "Accuracy")
            Spacer()
            resultStat(value: "\(session.score)", label: "Correct")
            Spacer()
            resultStat(value: "\(session.totalQuestions - session.score)", label: "Missed")
            Spacer()
            resultStat(value: "\(session.totalQuestions)", label: "Total")
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 10)
        .animation(.easeOut(duration: 0.38).delay(0.08), value: appear)
    }

    private func resultStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.text)
                .monospacedDigit()
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
                .kerning(0.8)
        }
    }

    // MARK: - Time Row

    private var timeRow: some View {
        HStack {
            Text("Time")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(timeString)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.text)
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.38).delay(0.12), value: appear)
    }

    // MARK: - Wrong Answers

    private var wrongAnswersSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Toggle header
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    showWrongAnswers.toggle()
                }
            } label: {
                HStack {
                    Text("Missed Words")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(AppTheme.textTertiary)
                        .kerning(1.2)
                    Spacer()
                    Image(systemName: showWrongAnswers ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppTheme.textTertiary)
                    Text("\(wrongWords.count)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(AppTheme.textTertiary)
                }
                .padding(.horizontal, 28)
            }
            .buttonStyle(.plain)

            if showWrongAnswers {
                VStack(spacing: 0) {
                    ForEach(Array(wrongWords.enumerated()), id: \.element.id) { i, word in
                        MissedWordRow(word: word)

                        if i < wrongWords.count - 1 {
                            MinimalDivider().padding(.leading, 28)
                        }
                    }
                }
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            MinimalDivider()
                .padding(.top, 20)
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.38).delay(0.16), value: appear)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button(action: onPlayAgain) {
                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.text)
                    )
            }
            .buttonStyle(.plain)

            Text("Results saved to your spaced repetition queue.")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 16)
        .animation(.easeOut(duration: 0.38).delay(0.20), value: appear)
    }

    // MARK: - Computed

    private var resultEmoji: String {
        if isPerfect      { return "🏆" }
        if accuracy >= 0.8 { return "⭐️" }
        if accuracy >= 0.6 { return "💪" }
        return "📚"
    }

    private var resultTitle: String {
        if isPerfect       { return "Perfect." }
        if accuracy >= 0.8  { return "Well done." }
        if accuracy >= 0.6  { return "Good effort." }
        return "Keep going."
    }

    private var resultSubtitle: String {
        if isPerfect       { return "Flawless. Every single word." }
        if accuracy >= 0.8  { return "Strong performance. The words are sticking." }
        if accuracy >= 0.6  { return "Solid work. More reps will seal it in." }
        return "The hard words are the most valuable. Review and retry."
    }

    private var timeString: String {
        let s = Int(session.elapsedTime)
        let m = s / 60
        let sec = s % 60
        return m > 0 ? "\(m)m \(sec)s" : "\(sec)s"
    }
}

// MARK: - Missed Word Row

private struct MissedWordRow: View {
    let word: Word

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 3)
                .fill(CardPalette.color(for: word.category))
                .frame(width: 3, height: 36)
                .padding(.leading, 28)
                .padding(.vertical, 14)

            VStack(alignment: .leading, spacing: 3) {
                Text(word.word)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.text)
                Text(word.definition)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 14)
            .padding(.trailing, 28)
        }
    }
}
