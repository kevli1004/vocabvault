import SwiftUI

// MARK: - Quiz View
// Full-screen color cards. Typography-forward. Minimal answer buttons.

struct QuizView: View {
    @EnvironmentObject var store: WordStore
    @State private var session: QuizEngine.QuizSession?
    @State private var selectedAnswer: String? = nil
    @State private var showFeedback = false
    @State private var isCorrect = false
    @State private var quizConfig = QuizConfig()
    @State private var feedbackFlash: Color? = nil

    struct QuizConfig {
        var questionCount: Int = 10
        var onlyDue: Bool = false
        var types: Set<QuizEngine.QuestionType> = Set(QuizEngine.QuestionType.allCases)
    }

    var body: some View {
        ZStack {
            if let s = session {
                if s.isComplete {
                    quizCompleteView(session: s)
                        .transition(.opacity)
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
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Title
                Text("Quiz")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(AppTheme.text)

                Text("Test your vocabulary")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 8)

                Spacer().frame(height: 60)

                // Question count selector
                HStack(spacing: 16) {
                    ForEach([5, 10, 15, 20], id: \.self) { count in
                        Button {
                            quizConfig.questionCount = count
                        } label: {
                            Text("\(count)")
                                .font(.system(size: 20, weight: quizConfig.questionCount == count ? .bold : .regular))
                                .foregroundColor(quizConfig.questionCount == count ? AppTheme.text : AppTheme.textTertiary)
                        }
                        .buttonStyle(.plain)
                        .animation(.easeOut(duration: 0.12), value: quizConfig.questionCount)
                    }
                }

                Text("questions")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppTheme.textTertiary)
                    .padding(.top, 6)

                Spacer().frame(height: 40)

                // Due words toggle
                Button {
                    quizConfig.onlyDue.toggle()
                } label: {
                    Text(quizConfig.onlyDue ? "Due words only" : "All words")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(quizConfig.onlyDue ? AppTheme.text : AppTheme.textTertiary)
                }
                .buttonStyle(.plain)

                Spacer()

                // Start
                Button(action: startQuiz) {
                    Text("Begin")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.text)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 100)
            }
        }
    }

    // MARK: - Quiz Content

    @ViewBuilder
    private func quizContent(session: QuizEngine.QuizSession) -> some View {
        if let question = session.currentQuestion {
            let cardColor = CardPalette.rotating(index: session.currentIndex)

            ZStack {
                // Full-screen color background
                cardColor.ignoresSafeArea()

                // Feedback flash overlay
                if let flash = feedbackFlash {
                    flash.opacity(0.25)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                // Ultra-thin progress line at very top
                VStack(spacing: 0) {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(CardPalette.cardText.opacity(0.15))
                            .frame(width: geo.size.width * session.progress, height: 1)
                            .animation(.easeOut(duration: 0.3), value: session.progress)
                    }
                    .frame(height: 1)

                    Spacer()
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top bar: close + counter
                    HStack {
                        Button {
                            withAnimation { self.session = nil }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(CardPalette.cardText.opacity(0.5))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text("\(session.currentIndex + 1)/\(session.totalQuestions)")
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .foregroundColor(CardPalette.cardText.opacity(0.5))
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 60)

                    Spacer()

                    // Question type hint
                    Text(questionTypeLabel(question.type))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(CardPalette.cardText.opacity(0.4))
                        .kerning(0.8)

                    // Prompt — large, centered
                    Text(displayPrompt(question))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(CardPalette.cardText)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 32)
                        .padding(.top, 12)

                    Spacer()

                    // Answer options — clean text, no borders
                    VStack(spacing: 20) {
                        ForEach(Array(question.choices.enumerated()), id: \.offset) { _, choice in
                            Button {
                                guard !showFeedback else { return }
                                submitAnswer(choice, question: question)
                            } label: {
                                Text(choice)
                                    .font(.system(size: 16, weight: answerWeight(for: choice)))
                                    .foregroundColor(answerColor(for: choice, question: question))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            .animation(.easeOut(duration: 0.15), value: selectedAnswer)
                        }
                    }
                    .padding(.horizontal, 36)
                    .padding(.bottom, 100)
                }
            }
        }
    }

    // MARK: - Quiz Complete

    private func quizCompleteView(session: QuizEngine.QuizSession) -> some View {
        let accuracy = session.totalQuestions > 0
            ? Double(session.score) / Double(session.totalQuestions)
            : 0

        return ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text("\(Int(accuracy * 100))%")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(AppTheme.text)
                    .monospacedDigit()

                Text(completeTitle(accuracy: accuracy))
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 12)

                // Score detail
                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text("\(session.score)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.text)
                        Text("CORRECT")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    VStack(spacing: 4) {
                        Text("\(session.totalQuestions - session.score)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.text)
                        Text("MISSED")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
                .padding(.top, 40)

                Spacer()

                Button {
                    startQuiz()
                } label: {
                    Text("Try Again")
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
                .padding(.bottom, 100)
            }
        }
    }

    // MARK: - Helpers

    private func displayPrompt(_ question: QuizEngine.Question) -> String {
        switch question.type {
        case .wordToDefinition, .synonymMatch:
            return question.word.word
        case .definitionToWord:
            return question.word.definition
        case .fillInTheBlank:
            return question.prompt
        }
    }

    private func answerWeight(for choice: String) -> Font.Weight {
        if selectedAnswer == choice { return .semibold }
        return .regular
    }

    private func answerColor(for choice: String, question: QuizEngine.Question) -> Color {
        guard showFeedback else {
            if selectedAnswer == choice {
                return CardPalette.cardText
            }
            return CardPalette.cardText.opacity(0.7)
        }

        if choice == question.correctAnswer {
            return CardPalette.cardText
        }
        if choice == selectedAnswer && !isCorrect {
            return CardPalette.cardText.opacity(0.3)
        }
        return CardPalette.cardText.opacity(0.25)
    }

    private func questionTypeLabel(_ type: QuizEngine.QuestionType) -> String {
        switch type {
        case .wordToDefinition:  return "WHAT DOES THIS MEAN?"
        case .definitionToWord:  return "WHICH WORD IS THIS?"
        case .fillInTheBlank:    return "FILL IN THE BLANK"
        case .synonymMatch:      return "FIND THE SYNONYM"
        }
    }

    private func completeTitle(accuracy: Double) -> String {
        if accuracy == 1.0 { return "Perfect." }
        if accuracy >= 0.8  { return "Well done." }
        if accuracy >= 0.5  { return "Good effort." }
        return "Keep at it."
    }

    // MARK: - Actions

    private func startQuiz() {
        let words = quizConfig.onlyDue ? store.dueWords : store.words
        let newSession = QuizEngine.buildQuizSession(
            from: words,
            count: min(quizConfig.questionCount, words.count),
            questionTypes: Array(quizConfig.types)
        )
        selectedAnswer = nil
        showFeedback = false
        feedbackFlash = nil
        withAnimation(.easeOut(duration: 0.25)) { session = newSession }
    }

    private func submitAnswer(_ answer: String, question: QuizEngine.Question) {
        selectedAnswer = answer
        isCorrect = answer == question.correctAnswer

        UIImpactFeedbackGenerator(style: isCorrect ? .light : .medium).impactOccurred()

        // Brief full-screen color flash
        withAnimation(.easeIn(duration: 0.15)) {
            feedbackFlash = isCorrect
                ? Color(red: 0.2, green: 0.7, blue: 0.3)
                : Color(red: 0.8, green: 0.2, blue: 0.2)
            showFeedback = true
        }

        if isCorrect {
            store.markCorrect(wordId: question.word.id)
        } else {
            store.markIncorrect(wordId: question.word.id)
        }

        // Auto-advance after brief flash
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            advanceQuestion(answer)
        }
    }

    private func advanceQuestion(_ answer: String) {
        guard var s = session else { return }

        withAnimation(.easeOut(duration: 0.15)) {
            feedbackFlash = nil
        }

        QuizEngine.answer(session: &s, with: answer)
        withAnimation(.easeInOut(duration: 0.25)) {
            session = s
            showFeedback = false
            selectedAnswer = nil
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
        Button(action: onTap) {
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(AppTheme.text)
        }
        .buttonStyle(.plain)
    }
}
