import SwiftUI

// MARK: - Quiz View
// Cream background. Typography-forward. Clean answer options.

struct QuizView: View {
    @EnvironmentObject var store: WordStore
    @State private var session: QuizEngine.QuizSession?
    @State private var selectedAnswer: String? = nil
    @State private var showFeedback = false
    @State private var isCorrect = false
    @State private var quizConfig = QuizConfig()
    @State private var cardOffset: CGFloat = 0
    @State private var cardOpacity: Double = 1

    struct QuizConfig {
        var questionCount: Int = 10
        var onlyDue: Bool = false
        var types: Set<QuizEngine.QuestionType> = Set(QuizEngine.QuestionType.allCases)
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if let s = session {
                if s.isComplete {
                    QuizResultsView(session: s, allWords: store.words) {
                        startQuiz()
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    quizContent(session: s)
                        .transition(.opacity)
                }
            } else {
                quizSetupView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: session?.isComplete)
    }

    // MARK: - Setup Screen

    private var quizSetupView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("Quiz")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(AppTheme.text)
                Text("Test your vocabulary")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal, 28)
            .padding(.top, 64)
            .padding(.bottom, 32)

            MinimalDivider()

            // Configuration
            VStack(spacing: 0) {
                // Question count
                VStack(alignment: .leading, spacing: 14) {
                    Text("Questions")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(AppTheme.textTertiary)
                        .kerning(1.2)

                    HStack(spacing: 10) {
                        ForEach([5, 10, 15, 20], id: \.self) { count in
                            Button {
                                quizConfig.questionCount = count
                            } label: {
                                Text("\(count)")
                                    .font(.system(size: 17, weight: quizConfig.questionCount == count ? .semibold : .regular))
                                    .foregroundColor(quizConfig.questionCount == count ? AppTheme.text : AppTheme.textTertiary)
                                    .frame(width: 58, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(quizConfig.questionCount == count ? AppTheme.surface : Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(
                                                        quizConfig.questionCount == count ? AppTheme.border : AppTheme.separator,
                                                        lineWidth: 1
                                                    )
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                            .animation(.easeOut(duration: 0.15), value: quizConfig.questionCount)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)

                MinimalDivider()

                // Focus on due
                Toggle(isOn: $quizConfig.onlyDue) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Focus on due words")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(AppTheme.text)
                        Text("Only quiz words scheduled for review")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
                .tint(AppTheme.text)
                .padding(.horizontal, 28)
                .padding(.vertical, 20)
            }

            MinimalDivider()

            // Stats preview
            HStack(spacing: 0) {
                statPreview(value: "\(wordsAvailable)", label: "Available")
                Spacer()
                statPreview(value: "\(store.totalMastered)", label: "Mastered")
                Spacer()
                statPreview(value: "\(store.dueCount)", label: "Due Now")
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 24)

            MinimalDivider()

            Spacer()

            // Start CTA
            Button(action: startQuiz) {
                Text("Begin Quiz")
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
            .padding(.horizontal, 28)
            .padding(.bottom, 100)
        }
    }

    private func statPreview(value: String, label: String) -> some View {
        VStack(spacing: 4) {
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

    private var wordsAvailable: Int {
        quizConfig.onlyDue ? store.dueCount : store.totalWords
    }

    // MARK: - Quiz Content

    @ViewBuilder
    private func quizContent(session: QuizEngine.QuizSession) -> some View {
        VStack(spacing: 0) {
            quizHeader(session: session)

            Spacer(minLength: 24)

            if let question = session.currentQuestion {
                questionContent(question: question, session: session)
                    .padding(.horizontal, 24)
                    .offset(y: cardOffset)
                    .opacity(cardOpacity)
            }

            Spacer(minLength: 32)
        }
    }

    // MARK: - Quiz Header

    private func quizHeader(session: QuizEngine.QuizSession) -> some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    self.session = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(AppTheme.surface).overlay(Circle().strokeBorder(AppTheme.border, lineWidth: 1)))
                }
                .buttonStyle(.plain)

                Spacer()

                Text("\(session.currentIndex + 1) of \(session.totalQuestions)")
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(AppTheme.textSecondary)

                Spacer()

                // Score indicator
                HStack(spacing: 5) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.success)
                    Text("\(session.score)")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(AppTheme.text)
                }
                .frame(width: 36)
            }
            .padding(.horizontal, 24)
            .padding(.top, 56)

            // Progress bar
            ThinProgressBar(
                current: session.currentIndex,
                total: session.totalQuestions,
                height: 1.5
            )
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Question Content

    @ViewBuilder
    private func questionContent(question: QuizEngine.Question, session: QuizEngine.QuizSession) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            // Type label
            Text(questionTypeLabel(question.type))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
                .kerning(1.2)

            // Prompt
            Text(question.prompt)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(AppTheme.text)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            MinimalDivider()

            // Answer options
            VStack(spacing: 10) {
                ForEach(Array(question.choices.enumerated()), id: \.offset) { idx, choice in
                    QuizAnswerButton(
                        text: choice,
                        index: idx,
                        state: answerState(for: choice, question: question)
                    ) {
                        guard !showFeedback else { return }
                        submitAnswer(choice, question: question)
                    }
                }
            }

            // Feedback strip
            if showFeedback {
                feedbackStrip(isCorrect: isCorrect, correctAnswer: question.correctAnswer)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func feedbackStrip(isCorrect: Bool, correctAnswer: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isCorrect ? "checkmark" : "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isCorrect ? AppTheme.success : AppTheme.error)
                .frame(width: 24, height: 24)
                .background(Circle().fill(isCorrect ? AppTheme.success.opacity(0.12) : AppTheme.error.opacity(0.12)))

            Text(isCorrect ? "Correct" : "Correct answer: \(correctAnswer)")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(isCorrect ? AppTheme.success : AppTheme.error)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isCorrect ? AppTheme.success.opacity(0.08) : AppTheme.error.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(isCorrect ? AppTheme.success.opacity(0.2) : AppTheme.error.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func answerState(for choice: String, question: QuizEngine.Question) -> QuizAnswerButton.AnswerState {
        guard showFeedback else { return .neutral }
        if choice == question.correctAnswer { return .correct }
        if choice == selectedAnswer && !isCorrect { return .incorrect }
        return .dimmed
    }

    // MARK: - Actions

    private func startQuiz() {
        let words = quizConfig.onlyDue ? store.dueWords : store.words
        let newSession = QuizEngine.buildQuizSession(
            from: words,
            count: min(quizConfig.questionCount, words.count),
            questionTypes: Array(quizConfig.types)
        )
        withAnimation(.easeOut(duration: 0.25)) { session = newSession }
    }

    private func submitAnswer(_ answer: String, question: QuizEngine.Question) {
        selectedAnswer = answer
        isCorrect = answer == question.correctAnswer

        UIImpactFeedbackGenerator(style: isCorrect ? .light : .medium).impactOccurred()

        withAnimation(.easeOut(duration: 0.2)) { showFeedback = true }

        if isCorrect {
            store.markCorrect(wordId: question.word.id)
        } else {
            store.markIncorrect(wordId: question.word.id)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            advanceQuestion(answer)
        }
    }

    private func advanceQuestion(_ answer: String) {
        guard var s = session else { return }

        withAnimation(.easeIn(duration: 0.18)) {
            cardOffset = -24
            cardOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            QuizEngine.answer(session: &s, with: answer)
            session = s
            showFeedback = false
            selectedAnswer = nil
            cardOffset = 28

            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                cardOffset = 0
                cardOpacity = 1
            }
        }
    }

    private func questionTypeLabel(_ type: QuizEngine.QuestionType) -> String {
        switch type {
        case .wordToDefinition:  return "What does this mean?"
        case .definitionToWord:  return "Which word is it?"
        case .fillInTheBlank:    return "Fill in the blank"
        case .synonymMatch:      return "Find the synonym"
        }
    }
}

// MARK: - Quiz Answer Button (minimal outlined style)

struct QuizAnswerButton: View {
    let text: String
    let index: Int
    let state: AnswerState
    let onTap: () -> Void

    enum AnswerState { case neutral, correct, incorrect, dimmed }

    private let letters = ["A", "B", "C", "D"]

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Letter
                Text(index < letters.count ? letters[index] : "")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(letterForeground)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(letterBackground)
                            .overlay(Circle().strokeBorder(letterBorder, lineWidth: 1))
                    )

                Text(text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                // Result icon
                if state == .correct {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.success)
                } else if state == .incorrect {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.error)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(buttonBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(buttonBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.18), value: state)
    }

    // MARK: - State-based styling

    private var buttonBackground: Color {
        switch state {
        case .neutral:   return AppTheme.surface
        case .correct:   return AppTheme.success.opacity(0.08)
        case .incorrect: return AppTheme.error.opacity(0.08)
        case .dimmed:    return AppTheme.surface.opacity(0.5)
        }
    }

    private var buttonBorder: Color {
        switch state {
        case .neutral:   return AppTheme.border
        case .correct:   return AppTheme.success.opacity(0.5)
        case .incorrect: return AppTheme.error.opacity(0.5)
        case .dimmed:    return AppTheme.separator
        }
    }

    private var textColor: Color {
        switch state {
        case .neutral:   return AppTheme.text
        case .correct:   return AppTheme.success
        case .incorrect: return AppTheme.error
        case .dimmed:    return AppTheme.textTertiary
        }
    }

    private var letterForeground: Color {
        switch state {
        case .neutral:   return AppTheme.textSecondary
        case .correct:   return AppTheme.success
        case .incorrect: return AppTheme.error
        case .dimmed:    return AppTheme.textTertiary
        }
    }

    private var letterBackground: Color {
        switch state {
        case .neutral:   return AppTheme.background
        case .correct:   return AppTheme.success.opacity(0.1)
        case .incorrect: return AppTheme.error.opacity(0.1)
        case .dimmed:    return AppTheme.background
        }
    }

    private var letterBorder: Color {
        switch state {
        case .neutral:   return AppTheme.border
        case .correct:   return AppTheme.success.opacity(0.3)
        case .incorrect: return AppTheme.error.opacity(0.3)
        case .dimmed:    return AppTheme.separator
        }
    }
}

// MARK: - Legacy AnswerButton compatibility

struct AnswerButton: View {
    let text: String
    let index: Int
    let state: AnswerState
    let onTap: () -> Void

    enum AnswerState { case neutral, correct, incorrect }

    var body: some View {
        QuizAnswerButton(
            text: text,
            index: index,
            state: {
                switch state {
                case .neutral:   return .neutral
                case .correct:   return .correct
                case .incorrect: return .incorrect
                }
            }(),
            onTap: onTap
        )
    }
}
