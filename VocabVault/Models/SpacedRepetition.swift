import Foundation

// MARK: - SM-2 Spaced Repetition Algorithm

struct SpacedRepetition {

    // MARK: - Grade

    /// Represents user's performance rating on a card
    enum Grade: Int {
        case blackout     = 0  // Complete blackout / wrong
        case incorrect    = 1  // Incorrect but recognized on seeing answer
        case correct      = 2  // Correct with serious difficulty
        case easy         = 3  // Correct after hesitation
        case perfect      = 4  // Perfect recall
        case effortless   = 5  // Perfect recall, instantly
    }

    // MARK: - Review Result

    struct ReviewResult {
        let newMasteryLevel: MasteryLevel
        let newInterval: Int          // days
        let newEaseFactor: Double
        let newRepetitions: Int
        let nextReviewDate: Date
    }

    // MARK: - Core SM-2 Algorithm

    /// Process a review and return updated spaced-repetition values
    static func processReview(
        word: Word,
        grade: Grade
    ) -> ReviewResult {
        let q = grade.rawValue
        var ef = word.easeFactor
        var interval = word.interval
        var repetitions = word.repetitions

        if q >= 3 {
            // Correct response
            switch repetitions {
            case 0:
                interval = 1
            case 1:
                interval = 3
            default:
                interval = Int((Double(interval) * ef).rounded())
            }
            repetitions += 1
        } else {
            // Incorrect — reset
            repetitions = 0
            interval = 1
        }

        // Update ease factor (bounded between 1.3 and 2.5)
        ef = ef + 0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02)
        ef = max(1.3, min(2.5, ef))

        // Cap interval at 180 days
        interval = min(interval, 180)

        // Calculate next review date
        let nextDate = Calendar.current.date(
            byAdding: .day,
            value: interval,
            to: Date()
        ) ?? Date()

        // Determine mastery level
        let masteryLevel = masteryLevelForRepetitions(repetitions, interval: interval)

        return ReviewResult(
            newMasteryLevel: masteryLevel,
            newInterval: interval,
            newEaseFactor: ef,
            newRepetitions: repetitions,
            nextReviewDate: nextDate
        )
    }

    // MARK: - Simplified Grade Helpers

    /// Call when user swipes RIGHT ("I know this")
    static func processCorrect(word: Word) -> ReviewResult {
        processReview(word: word, grade: .easy)
    }

    /// Call when user swipes LEFT ("Need more practice")
    static func processIncorrect(word: Word) -> ReviewResult {
        processReview(word: word, grade: .blackout)
    }

    // MARK: - Mastery Thresholds

    private static func masteryLevelForRepetitions(_ reps: Int, interval: Int) -> MasteryLevel {
        switch reps {
        case 0:
            return .new
        case 1...2:
            return .learning
        case 3...5:
            return .reviewing
        default:
            return interval >= 21 ? .mastered : .reviewing
        }
    }

    // MARK: - Session Helpers

    /// Returns words due for review today, sorted by overdue-ness
    static func dueWords(from words: [Word]) -> [Word] {
        let now = Date()
        return words
            .filter { $0.nextReviewDate <= now }
            .sorted {
                $0.nextReviewDate < $1.nextReviewDate
            }
    }

    /// Returns all new words (never studied)
    static func newWords(from words: [Word]) -> [Word] {
        words.filter { $0.masteryLevel == .new }
    }

    /// Returns a study session: due words first, then new words, up to limit
    static func buildStudySession(from words: [Word], limit: Int = 20) -> [Word] {
        let due = dueWords(from: words)
        let new = newWords(from: words)
        let combined = due + new
        return Array(combined.prefix(limit))
    }

    /// Estimated days until a word is "mastered" (interval >= 21)
    static func estimatedDaysToMastery(word: Word) -> Int {
        var interval = word.interval
        var repetitions = word.repetitions
        var ef = word.easeFactor
        var totalDays = 0

        while interval < 21 && totalDays < 365 {
            switch repetitions {
            case 0:
                interval = 1
            case 1:
                interval = 3
            default:
                interval = Int((Double(interval) * ef).rounded())
            }
            interval = min(interval, 180)
            repetitions += 1
            totalDays += interval
        }

        return totalDays
    }
}
