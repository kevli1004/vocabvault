import Foundation
import Combine

// MARK: - Word Store

@MainActor
final class WordStore: ObservableObject {

    // MARK: - Published State

    @Published private(set) var words: [Word] = []
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var longestStreak: Int = 0
    @Published private(set) var totalReviews: Int = 0
    @Published private(set) var dailyGoal: Int = 20
    @Published private(set) var reviewedToday: Int = 0
    @Published private(set) var lastStudyDate: Date?

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let progressData    = "vv_progress_v2"
        static let streak          = "vv_streak"
        static let longestStreak   = "vv_longest_streak"
        static let totalReviews    = "vv_total_reviews"
        static let dailyGoal       = "vv_daily_goal"
        static let reviewedToday   = "vv_reviewed_today"
        static let lastStudyDate   = "vv_last_study_date"
        static let lastStudyDateTS = "vv_last_study_date_ts"
    }

    // MARK: - Init

    init() {
        loadWords()
        loadStats()
        checkStreakReset()
    }

    // MARK: - Computed Properties

    var dueWords: [Word] {
        SpacedRepetition.dueWords(from: words)
    }

    var newWords: [Word] {
        SpacedRepetition.newWords(from: words)
    }

    var masteredWords: [Word] {
        words.filter { $0.masteryLevel == .mastered }
    }

    var favoriteWords: [Word] {
        words.filter { $0.isFavorite }
    }

    var studySession: [Word] {
        SpacedRepetition.buildStudySession(from: words, limit: dailyGoal)
    }

    var totalMastered: Int { masteredWords.count }
    var totalWords: Int { words.count }
    var dueCount: Int { dueWords.count }
    var newCount: Int { newWords.count }

    var overallAccuracy: Double {
        let correct = words.reduce(0) { $0 + $1.timesCorrect }
        let incorrect = words.reduce(0) { $0 + $1.timesIncorrect }
        let total = correct + incorrect
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    var categoryBreakdown: [(WordCategory, Int)] {
        WordCategory.allCases.map { cat in
            (cat, words.filter { $0.category == cat }.count)
        }.filter { $0.1 > 0 }
    }

    var masteryBreakdown: [(MasteryLevel, Int)] {
        MasteryLevel.allCases.map { level in
            (level, words.filter { $0.masteryLevel == level }.count)
        }
    }

    var weeklyProgress: [Int] {
        // Returns count of words reviewed per day for last 7 days
        (0..<7).map { daysAgo in
            let targetDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            return words.filter { word in
                guard let reviewDate = Calendar.current.date(
                    byAdding: .day, value: -word.interval, to: word.nextReviewDate
                ) else { return false }
                return Calendar.current.isDate(reviewDate, inSameDayAs: targetDate)
            }.count
        }.reversed()
    }

    // MARK: - Review Actions

    func markCorrect(wordId: String) {
        guard let idx = index(of: wordId) else { return }
        let result = SpacedRepetition.processCorrect(word: words[idx])
        applyResult(result, to: idx, wasCorrect: true)
    }

    func markIncorrect(wordId: String) {
        guard let idx = index(of: wordId) else { return }
        let result = SpacedRepetition.processIncorrect(word: words[idx])
        applyResult(result, to: idx, wasCorrect: false)
    }

    func toggleFavorite(wordId: String) {
        guard let idx = index(of: wordId) else { return }
        words[idx].isFavorite.toggle()
        saveProgress()
    }

    func setDailyGoal(_ goal: Int) {
        dailyGoal = max(5, min(100, goal))
        UserDefaults.standard.set(dailyGoal, forKey: Keys.dailyGoal)
    }

    func resetProgress() {
        words = Word.allWords
        currentStreak = 0
        longestStreak = 0
        totalReviews = 0
        reviewedToday = 0
        lastStudyDate = nil
        saveAll()
    }

    // MARK: - Search & Filter

    func words(in category: WordCategory) -> [Word] {
        words.filter { $0.category == category }
    }

    func words(at masteryLevel: MasteryLevel) -> [Word] {
        words.filter { $0.masteryLevel == masteryLevel }
    }

    func words(matching query: String) -> [Word] {
        guard !query.isEmpty else { return words }
        let q = query.lowercased()
        return words.filter {
            $0.word.lowercased().contains(q) ||
            $0.definition.lowercased().contains(q)
        }
    }

    func word(id: String) -> Word? {
        words.first { $0.id == id }
    }

    // MARK: - Private Helpers

    private func applyResult(_ result: SpacedRepetition.ReviewResult, to idx: Int, wasCorrect: Bool) {
        words[idx].masteryLevel  = result.newMasteryLevel
        words[idx].interval      = result.newInterval
        words[idx].easeFactor    = result.newEaseFactor
        words[idx].repetitions   = result.newRepetitions
        words[idx].nextReviewDate = result.nextReviewDate

        if wasCorrect {
            words[idx].timesCorrect += 1
        } else {
            words[idx].timesIncorrect += 1
        }

        totalReviews += 1
        reviewedToday += 1
        lastStudyDate = Date()

        if wasCorrect {
            incrementStreak()
        }

        saveAll()
    }

    private func incrementStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        if let last = lastStudyDate {
            let lastDay = Calendar.current.startOfDay(for: last)
            let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff == 0 {
                // same day, already incremented
                return
            } else if diff == 1 {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }
        longestStreak = max(currentStreak, longestStreak)
    }

    private func checkStreakReset() {
        guard let lastDate = lastStudyDate else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let lastDay = Calendar.current.startOfDay(for: lastDate)
        let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
        if diff > 1 {
            currentStreak = 0
            UserDefaults.standard.set(0, forKey: Keys.streak)
        }
        // Reset daily count if new day
        if diff >= 1 {
            reviewedToday = 0
            UserDefaults.standard.set(0, forKey: Keys.reviewedToday)
        }
    }

    private func index(of wordId: String) -> Int? {
        words.firstIndex { $0.id == wordId }
    }

    // MARK: - Persistence

    private func loadWords() {
        guard
            let data = UserDefaults.standard.data(forKey: Keys.progressData),
            let savedProgress = try? JSONDecoder().decode([String: WordProgressData].self, from: data)
        else {
            words = Word.allWords
            return
        }

        // Merge saved progress onto fresh word list
        words = Word.allWords.map { word in
            var w = word
            if let saved = savedProgress[word.id] {
                w.masteryLevel   = saved.masteryLevel
                w.interval       = saved.interval
                w.easeFactor     = saved.easeFactor
                w.repetitions    = saved.repetitions
                w.nextReviewDate = saved.nextReviewDate
                w.isFavorite     = saved.isFavorite
                w.timesCorrect   = saved.timesCorrect
                w.timesIncorrect = saved.timesIncorrect
            }
            return w
        }
    }

    private func loadStats() {
        currentStreak  = UserDefaults.standard.integer(forKey: Keys.streak)
        longestStreak  = UserDefaults.standard.integer(forKey: Keys.longestStreak)
        totalReviews   = UserDefaults.standard.integer(forKey: Keys.totalReviews)
        dailyGoal      = UserDefaults.standard.integer(forKey: Keys.dailyGoal).nonZeroOr(20)
        reviewedToday  = UserDefaults.standard.integer(forKey: Keys.reviewedToday)

        if let ts = UserDefaults.standard.object(forKey: Keys.lastStudyDateTS) as? Double {
            lastStudyDate = Date(timeIntervalSince1970: ts)
        }
    }

    func saveProgress() {
        let progressData = Dictionary(uniqueKeysWithValues: words.map { word in
            (word.id, WordProgressData(from: word))
        })
        if let data = try? JSONEncoder().encode(progressData) {
            UserDefaults.standard.set(data, forKey: Keys.progressData)
        }
    }

    private func saveStats() {
        UserDefaults.standard.set(currentStreak,  forKey: Keys.streak)
        UserDefaults.standard.set(longestStreak,  forKey: Keys.longestStreak)
        UserDefaults.standard.set(totalReviews,   forKey: Keys.totalReviews)
        UserDefaults.standard.set(reviewedToday,  forKey: Keys.reviewedToday)
        if let date = lastStudyDate {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Keys.lastStudyDateTS)
        }
    }

    private func saveAll() {
        saveProgress()
        saveStats()
    }
}

// MARK: - Codable Progress Snapshot

private struct WordProgressData: Codable {
    var masteryLevel: MasteryLevel
    var interval: Int
    var easeFactor: Double
    var repetitions: Int
    var nextReviewDate: Date
    var isFavorite: Bool
    var timesCorrect: Int
    var timesIncorrect: Int

    init(from word: Word) {
        masteryLevel   = word.masteryLevel
        interval       = word.interval
        easeFactor     = word.easeFactor
        repetitions    = word.repetitions
        nextReviewDate = word.nextReviewDate
        isFavorite     = word.isFavorite
        timesCorrect   = word.timesCorrect
        timesIncorrect = word.timesIncorrect
    }
}

// MARK: - Int extension

private extension Int {
    func nonZeroOr(_ fallback: Int) -> Int {
        self == 0 ? fallback : self
    }
}
