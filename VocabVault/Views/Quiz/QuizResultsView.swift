import SwiftUI

// MARK: - Quiz Results View

struct QuizResultsView: View {
    let session: QuizEngine.QuizSession
    let allWords: [Word]
    let onPlayAgain: () -> Void

    @State private var showConfetti = false
    @State private var appear = false
    @State private var showWrongAnswers = false

    private var accuracy: Double { session.accuracy }
    private var isPerfect: Bool { session.isPerfectScore }

    private var wrongWords: [Word] {
        let ids = QuizEngine.wrongAnswerIds(from: session)
        return allWords.filter { ids.contains($0.id) }
    }

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Trophy
                    trophySection

                    // Score ring
                    scoreRingSection

                    // Stats cards
                    statsRow

                    // Time
                    GlassCard(cornerRadius: 20, padding: 16, opacity: 0.1) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.gradTeal1)
                            Text("Completed in")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text(timeString)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Wrong answers review
                    if !wrongWords.isEmpty {
                        wrongAnswersSection
                    }

                    // Buttons
                    VStack(spacing: 12) {
                        Button(action: onPlayAgain) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                Text("Play Again")
                            }
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule().fill(LinearGradient.pastelGradient(for: .coral))
                            )
                        }

                        Text("Results saved to spaced repetition queue")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appear = true
            }
            if isPerfect {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showConfetti = true
                }
            }
        }
    }

    // MARK: - Trophy

    private var trophySection: some View {
        VStack(spacing: 12) {
            Text(trophyEmoji)
                .font(.system(size: 80))
                .floating(amplitude: 10)
                .scaleEffect(appear ? 1 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: appear)

            Text(resultTitle)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.15), value: appear)

            Text(resultSubtitle)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .opacity(appear ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: appear)
        }
        .padding(.top, 40)
        .padding(.horizontal, 24)
    }

    // MARK: - Score Ring

    private var scoreRingSection: some View {
        ZStack {
            ProgressRing(
                progress: accuracy,
                lineWidth: 14,
                ringColor: ringColor,
                showLabel: false
            )
            .frame(width: 140, height: 140)

            VStack(spacing: 2) {
                Text("\(Int(accuracy * 100))")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("% accuracy")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .scaleEffect(appear ? 1 : 0.7)
        .opacity(appear ? 1 : 0)
        .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2), value: appear)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            ResultStatCard(
                icon: "checkmark.circle.fill",
                value: "\(session.score)",
                label: "Correct",
                color: .swipeRight
            )
            ResultStatCard(
                icon: "xmark.circle.fill",
                value: "\(session.totalQuestions - session.score)",
                label: "Wrong",
                color: .swipeLeft
            )
            ResultStatCard(
                icon: "questionmark.circle.fill",
                value: "\(session.totalQuestions)",
                label: "Total",
                color: .gradPurple1
            )
        }
        .padding(.horizontal, 24)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 20)
        .animation(.easeOut(duration: 0.4).delay(0.3), value: appear)
    }

    // MARK: - Wrong Answers

    private var wrongAnswersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring()) {
                    showWrongAnswers.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showWrongAnswers ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .foregroundColor(.gradAmber1)
                    Text("Review \(wrongWords.count) missed words")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .buttonStyle(.plain)

            if showWrongAnswers {
                VStack(spacing: 8) {
                    ForEach(wrongWords) { word in
                        GlassCard(cornerRadius: 16, padding: 14, opacity: 0.1) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(word.word)
                                        .font(.system(size: 16, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                    CategoryBadge(category: word.category)
                                }
                                Text(word.definition)
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Computed

    private var trophyEmoji: String {
        if isPerfect      { return "🏆" }
        if accuracy >= 0.8 { return "🌟" }
        if accuracy >= 0.6 { return "⭐️" }
        if accuracy >= 0.4 { return "💪" }
        return "📚"
    }

    private var resultTitle: String {
        if isPerfect       { return "Perfect Score!" }
        if accuracy >= 0.8 { return "Excellent Work!" }
        if accuracy >= 0.6 { return "Good Job!" }
        if accuracy >= 0.4 { return "Keep Practicing!" }
        return "Don't Give Up!"
    }

    private var resultSubtitle: String {
        if isPerfect       { return "You knew every single word! 🔥" }
        if accuracy >= 0.8 { return "Almost flawless. You're on a roll!" }
        if accuracy >= 0.6 { return "Solid performance. More reps will seal it." }
        if accuracy >= 0.4 { return "The hard words build character." }
        return "Review the missed words and try again."
    }

    private var ringColor: Color {
        if accuracy >= 0.8 { return .gradMint1 }
        if accuracy >= 0.6 { return .gradAmber1 }
        return .gradCoral1
    }

    private var timeString: String {
        let seconds = Int(session.elapsedTime)
        let m = seconds / 60
        let s = seconds % 60
        if m > 0 { return "\(m)m \(s)s" }
        return "\(s) seconds"
    }
}

// MARK: - Result Stat Card

private struct ResultStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(color.opacity(0.25), lineWidth: 1)
                )
        )
    }
}
