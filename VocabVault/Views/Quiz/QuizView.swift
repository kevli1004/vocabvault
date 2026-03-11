import SwiftUI

// MARK: - Quiz View

struct QuizView: View {
    @EnvironmentObject var store: WordStore
    @State private var session: QuizEngine.QuizSession?
    @State private var selectedAnswer: String? = nil
    @State private var showFeedback = false
    @State private var isCorrect = false
    @State private var quizConfig = QuizConfig()
    @State private var showConfig = false
    @State private var cardOffset: CGFloat = 0
    @State private var cardOpacity: Double = 1

    struct QuizConfig {
        var questionCount: Int = 10
        var onlyDue: Bool = false
        var types: Set<QuizEngine.QuestionType> = Set(QuizEngine.QuestionType.allCases)
    }

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            if let s = session {
                if s.isComplete {
                    QuizResultsView(session: s, allWords: store.words) {
                        startQuiz()
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    quizContent(session: s)
                }
            } else {
                quizSetupView
            }
        }
    }

    // MARK: - Setup Screen

    private var quizSetupView: some View {
        VStack(spacing: 28) {
            // Header
            VStack(spacing: 8) {
                Text("🧠")
                    .font(.system(size: 60))
                    .floating()
                Text("Quiz Mode")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("Test your vocabulary knowledge")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 40)

            // Config card
            GlassCard(cornerRadius: 24, padding: 24, opacity: 0.1) {
                VStack(spacing: 20) {
                    // Question count
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Questions")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                        HStack(spacing: 10) {
                            ForEach([5, 10, 15, 20], id: \.self) { count in
                                Button("\(count)") {
                                    quizConfig.questionCount = count
                                }
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(quizConfig.questionCount == count ? .white : .white.opacity(0.45))
                                .frame(width: 56, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(quizConfig.questionCount == count ? LinearGradient.pastelGradient(for: .coral) : LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                                )
                            }
                        }
                    }

                    Divider().background(Color.white.opacity(0.1))

                    // Only due
                    Toggle(isOn: $quizConfig.onlyDue) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Focus on due words")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Only quiz words scheduled for review")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .tint(.gradTeal1)
                }
            }
            .padding(.horizontal, 24)

            // Stats preview
            HStack(spacing: 20) {
                QuizStatPreview(label: "Available", value: "\(wordsAvailable)", icon: "books.vertical.fill", color: .gradPurple1)
                QuizStatPreview(label: "Mastered", value: "\(store.totalMastered)", icon: "star.fill", color: .gradAmber1)
                QuizStatPreview(label: "Due Now", value: "\(store.dueCount)", icon: "clock.fill", color: .gradCoral1)
            }
            .padding(.horizontal, 24)

            Spacer()

            // Start button
            Button(action: startQuiz) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                    Text("Start Quiz")
                }
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(LinearGradient.pastelGradient(for: .coral))
                )
                .shadow(color: .gradCoral2.opacity(0.5), radius: 16, x: 0, y: 8)
                .padding(.horizontal, 32)
            }
            .bouncyAppear()
            .padding(.bottom, 40)
        }
    }

    private var wordsAvailable: Int {
        quizConfig.onlyDue ? store.dueCount : store.totalWords
    }

    // MARK: - Quiz Content

    @ViewBuilder
    private func quizContent(session: QuizEngine.QuizSession) -> some View {
        VStack(spacing: 0) {
            // Header
            quizHeader(session: session)

            Spacer()

            // Question card
            if let question = session.currentQuestion {
                questionCard(question: question, session: session)
                    .padding(.horizontal, 20)
                    .offset(y: cardOffset)
                    .opacity(cardOpacity)
            }

            Spacer()
        }
    }

    private func quizHeader(session: QuizEngine.QuizSession) -> some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    self.session = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Text("\(session.currentIndex + 1) / \(session.totalQuestions)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                // Score
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.swipeRight)
                    Text("\(session.score)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(LinearGradient(colors: [.gradCoral1, .gradAmber1], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * session.progress)
                        .animation(.spring(response: 0.5), value: session.progress)
                }
            }
            .frame(height: 5)
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private func questionCard(question: QuizEngine.Question, session: QuizEngine.QuizSession) -> some View {
        VStack(spacing: 20) {
            // Question type badge
            Text(questionTypeBadge(question.type))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .kerning(1.2)

            // Prompt
            GlassCard(cornerRadius: 24, padding: 24, opacity: 0.12) {
                Text(question.prompt)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .lineSpacing(4)
            }

            // Answer choices
            VStack(spacing: 12) {
                ForEach(Array(question.choices.enumerated()), id: \.offset) { idx, choice in
                    AnswerButton(
                        text: choice,
                        index: idx,
                        state: answerState(for: choice, question: question),
                        onTap: {
                            guard !showFeedback else { return }
                            submitAnswer(choice, question: question)
                        }
                    )
                }
            }

            // Feedback
            if showFeedback {
                feedbackView(isCorrect: isCorrect, correctAnswer: question.correctAnswer)
            }
        }
    }

    private func answerState(for choice: String, question: QuizEngine.Question) -> AnswerButton.AnswerState {
        guard showFeedback else { return .neutral }
        if choice == question.correctAnswer { return .correct }
        if choice == selectedAnswer && !isCorrect { return .incorrect }
        return .neutral
    }

    private func feedbackView(isCorrect: Bool, correctAnswer: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(isCorrect ? .swipeRight : .swipeLeft)
            Text(isCorrect ? "Correct! 🎉" : "Correct: \(correctAnswer)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(isCorrect ? .swipeRight : .swipeLeft)
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill((isCorrect ? Color.swipeRight : Color.swipeLeft).opacity(0.12))
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions

    private func startQuiz() {
        let words = quizConfig.onlyDue ? store.dueWords : store.words
        let newSession = QuizEngine.buildQuizSession(
            from: words,
            count: min(quizConfig.questionCount, words.count),
            questionTypes: Array(quizConfig.types)
        )
        withAnimation(.spring()) {
            session = newSession
        }
    }

    private func submitAnswer(_ answer: String, question: QuizEngine.Question) {
        selectedAnswer = answer
        isCorrect = answer == question.correctAnswer

        let impact = UIImpactFeedbackGenerator(style: isCorrect ? .light : .medium)
        impact.impactOccurred()

        withAnimation(.spring()) {
            showFeedback = true
        }

        // Update store
        if isCorrect {
            store.markCorrect(wordId: question.word.id)
        } else {
            store.markIncorrect(wordId: question.word.id)
        }

        // Advance after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            advanceQuestion(answer)
        }
    }

    private func advanceQuestion(_ answer: String) {
        guard var s = session else { return }

        // Animate out
        withAnimation(.easeIn(duration: 0.2)) {
            cardOffset = -30
            cardOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            QuizEngine.answer(session: &s, with: answer)
            session = s
            showFeedback = false
            selectedAnswer = nil

            cardOffset = 40
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                cardOffset = 0
                cardOpacity = 1
            }
        }
    }

    private func questionTypeBadge(_ type: QuizEngine.QuestionType) -> String {
        switch type {
        case .wordToDefinition:  return "WHAT DOES IT MEAN?"
        case .definitionToWord:  return "WHICH WORD IS IT?"
        case .fillInTheBlank:    return "FILL IN THE BLANK"
        case .synonymMatch:      return "FIND THE SYNONYM"
        }
    }
}

// MARK: - Answer Button

struct AnswerButton: View {
    let text: String
    let index: Int
    let state: AnswerState
    let onTap: () -> Void

    enum AnswerState { case neutral, correct, incorrect }

    private let letters = ["A", "B", "C", "D"]

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Letter badge
                Text(index < letters.count ? letters[index] : "?")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(letterColor)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle().fill(letterBgColor)
                    )

                Text(text)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                Spacer()

                if state == .correct {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.swipeRight)
                } else if state == .incorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.swipeLeft)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(buttonBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(borderColor, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: state)
    }

    private var buttonBg: Color {
        switch state {
        case .neutral:   return Color.white.opacity(0.08)
        case .correct:   return Color.swipeRight.opacity(0.15)
        case .incorrect: return Color.swipeLeft.opacity(0.15)
        }
    }

    private var borderColor: Color {
        switch state {
        case .neutral:   return Color.white.opacity(0.12)
        case .correct:   return Color.swipeRight.opacity(0.6)
        case .incorrect: return Color.swipeLeft.opacity(0.6)
        }
    }

    private var letterColor: Color {
        switch state {
        case .neutral:   return Color.white.opacity(0.7)
        case .correct:   return .swipeRight
        case .incorrect: return .swipeLeft
        }
    }

    private var letterBgColor: Color {
        switch state {
        case .neutral:   return Color.white.opacity(0.12)
        case .correct:   return Color.swipeRight.opacity(0.2)
        case .incorrect: return Color.swipeLeft.opacity(0.2)
        }
    }
}

// MARK: - Quiz Stat Preview

private struct QuizStatPreview: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(color.opacity(0.1))
        )
    }
}
