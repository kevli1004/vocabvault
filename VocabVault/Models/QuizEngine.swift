import Foundation

// MARK: - Quiz Engine

struct QuizEngine {

    // MARK: - Question Types

    enum QuestionType: CaseIterable {
        case definitionToWord     // "What word means X?"
        case wordToDefinition     // "What does X mean?"
        case fillInTheBlank       // "Complete the sentence: ___"
        case synonymMatch         // "Which is a synonym of X?"
    }

    // MARK: - Question Model

    struct Question: Identifiable {
        let id = UUID()
        let type: QuestionType
        let word: Word
        let prompt: String
        let choices: [String]
        let correctAnswer: String
        var selectedAnswer: String? = nil

        var isAnswered: Bool { selectedAnswer != nil }
        var isCorrect: Bool { selectedAnswer == correctAnswer }
    }

    // MARK: - Quiz Session

    struct QuizSession {
        var questions: [Question]
        var currentIndex: Int = 0
        var score: Int = 0
        var startTime: Date = Date()
        var endTime: Date?

        var currentQuestion: Question? {
            guard currentIndex < questions.count else { return nil }
            return questions[currentIndex]
        }

        var isComplete: Bool { currentIndex >= questions.count }
        var progress: Double { Double(currentIndex) / Double(questions.count) }
        var totalQuestions: Int { questions.count }

        var accuracy: Double {
            guard score > 0 || currentIndex > 0 else { return 0 }
            return Double(score) / Double(max(currentIndex, 1))
        }

        var elapsedTime: TimeInterval {
            let end = endTime ?? Date()
            return end.timeIntervalSince(startTime)
        }

        var isPerfectScore: Bool { score == totalQuestions }
    }

    // MARK: - Question Generation

    static func buildQuizSession(
        from words: [Word],
        count: Int = 10,
        questionTypes: [QuestionType] = QuestionType.allCases
    ) -> QuizSession {
        guard words.count >= 4 else {
            return QuizSession(questions: [])
        }

        let selectedWords = Array(words.shuffled().prefix(count))
        let questions = selectedWords.compactMap { word in
            makeQuestion(for: word, from: words, type: questionTypes.randomElement() ?? .wordToDefinition)
        }

        return QuizSession(questions: questions)
    }

    static func buildReviewSession(incorrectWordIds: [String], allWords: [Word]) -> QuizSession {
        let incorrectWords = allWords.filter { incorrectWordIds.contains($0.id) }
        return buildQuizSession(from: incorrectWords, count: incorrectWords.count)
    }

    // MARK: - Private Question Factories

    private static func makeQuestion(
        for word: Word,
        from allWords: [Word],
        type: QuestionType
    ) -> Question? {
        // Need at least 4 words for multiple choice
        guard allWords.count >= 4 else { return nil }

        switch type {
        case .wordToDefinition:
            return makeWordToDefinition(word: word, allWords: allWords)
        case .definitionToWord:
            return makeDefinitionToWord(word: word, allWords: allWords)
        case .fillInTheBlank:
            return makeFillInTheBlank(word: word, allWords: allWords)
        case .synonymMatch:
            // Fall back if word has no synonyms or not enough words
            if word.synonyms.isEmpty {
                return makeWordToDefinition(word: word, allWords: allWords)
            }
            return makeSynonymMatch(word: word, allWords: allWords)
        }
    }

    private static func makeWordToDefinition(word: Word, allWords: [Word]) -> Question {
        let correct = word.definition
        let distractors = allWords
            .filter { $0.id != word.id }
            .shuffled()
            .prefix(3)
            .map { $0.definition }

        let choices = ([correct] + distractors).shuffled()

        return Question(
            type: .wordToDefinition,
            word: word,
            prompt: "What does \"\(word.word)\" mean?",
            choices: choices,
            correctAnswer: correct
        )
    }

    private static func makeDefinitionToWord(word: Word, allWords: [Word]) -> Question {
        let correct = word.word
        let distractors = allWords
            .filter { $0.id != word.id }
            .shuffled()
            .prefix(3)
            .map { $0.word }

        let choices = ([correct] + distractors).shuffled()

        return Question(
            type: .definitionToWord,
            word: word,
            prompt: "Which word matches this definition?\n\"\(word.definition)\"",
            choices: choices,
            correctAnswer: correct
        )
    }

    private static func makeFillInTheBlank(word: Word, allWords: [Word]) -> Question {
        // Replace the word in the example sentence with ___
        let blankedSentence = word.exampleSentence
            .replacingOccurrences(
                of: word.word,
                with: "_____",
                options: .caseInsensitive
            )

        let correct = word.word
        let distractors = allWords
            .filter {
                $0.id != word.id &&
                $0.category == word.category
            }
            .shuffled()
            .prefix(3)
            .map { $0.word }

        // If not enough same-category distractors, use any
        let allDistractors = distractors.count >= 3
            ? distractors
            : allWords.filter { $0.id != word.id }.shuffled().prefix(3).map { $0.word }

        let choices = ([correct] + allDistractors).shuffled()

        return Question(
            type: .fillInTheBlank,
            word: word,
            prompt: "Fill in the blank:\n\"\(blankedSentence)\"",
            choices: choices,
            correctAnswer: correct
        )
    }

    private static func makeSynonymMatch(word: Word, allWords: [Word]) -> Question {
        guard let correctSynonym = word.synonyms.first else {
            return makeWordToDefinition(word: word, allWords: allWords)
        }

        let distractors = allWords
            .filter { $0.id != word.id }
            .compactMap { $0.synonyms.first }
            .shuffled()
            .prefix(3)

        let choices = ([correctSynonym] + distractors).shuffled()

        return Question(
            type: .synonymMatch,
            word: word,
            prompt: "Which is a synonym of \"\(word.word)\"?",
            choices: choices,
            correctAnswer: correctSynonym
        )
    }

    // MARK: - Session Mutations

    static func answer(
        session: inout QuizSession,
        with answer: String
    ) {
        guard !session.isComplete else { return }
        guard session.currentIndex < session.questions.count else { return }

        session.questions[session.currentIndex].selectedAnswer = answer

        if session.questions[session.currentIndex].isCorrect {
            session.score += 1
        }

        session.currentIndex += 1

        if session.isComplete {
            session.endTime = Date()
        }
    }

    static func wrongAnswerIds(from session: QuizSession) -> [String] {
        session.questions
            .filter { $0.isAnswered && !$0.isCorrect }
            .map { $0.word.id }
    }
}
