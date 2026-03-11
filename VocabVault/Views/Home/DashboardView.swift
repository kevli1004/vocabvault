import SwiftUI

// MARK: - Dashboard / Stats View
// Editorial. The numbers tell the story. No charts, no decorations.

struct DashboardView: View {
    @EnvironmentObject var store: WordStore
    @State private var appear = false

    // MARK: - Body

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    header
                        .padding(.horizontal, 28)
                        .padding(.top, 64)
                        .padding(.bottom, 32)

                    MinimalDivider()
                        .padding(.horizontal, 28)

                    // Due-for-review CTA
                    reviewCTA
                        .padding(.horizontal, 28)
                        .padding(.top, 28)

                    MinimalDivider()
                        .padding(.horizontal, 28)
                        .padding(.top, 28)

                    // Key numbers
                    keyNumbers
                        .padding(.horizontal, 28)
                        .padding(.top, 28)

                    MinimalDivider()
                        .padding(.horizontal, 28)
                        .padding(.top, 28)

                    // Mastery breakdown
                    masteryBreakdown
                        .padding(.horizontal, 28)
                        .padding(.top, 28)

                    MinimalDivider()
                        .padding(.horizontal, 28)
                        .padding(.top, 28)

                    // Streak section
                    streakSection
                        .padding(.horizontal, 28)
                        .padding(.top, 28)
                        .padding(.bottom, 60)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) { appear = true }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("VocabVault")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
                .kerning(1.2)

            Text("Your Progress")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(AppTheme.text)
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 10)
    }

    // MARK: - Review CTA

    private var reviewCTA: some View {
        let dueCount = store.dueWords.count

        return HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dueCount > 0 ? "\(dueCount) words due" : "All caught up")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppTheme.text)

                Text(dueCount > 0
                     ? "Ready for review in your queue."
                     : "No reviews scheduled right now.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            if dueCount > 0 {
                VStack(spacing: 2) {
                    Text("\(dueCount)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppTheme.text)
                        .monospacedDigit()
                    Text("DUE")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(AppTheme.textTertiary)
                        .kerning(0.8)
                }
            } else {
                Text("✦")
                    .font(.system(size: 28))
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding(.bottom, 28)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 10)
        .animation(.easeOut(duration: 0.38).delay(0.06), value: appear)
    }

    // MARK: - Key Numbers

    private var keyNumbers: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Overview")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
                .kerning(1.2)

            // 2×2 grid of stats
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 24) {
                BigStat(value: "\(store.totalWords)", label: "Total Words")
                BigStat(value: "\(store.totalMastered)", label: "Mastered")
                BigStat(value: "\(store.totalReviews)", label: "Total Reviews")
                BigStat(value: "\(Int(store.overallAccuracy * 100))%", label: "Accuracy")
            }
        }
        .padding(.bottom, 28)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 10)
        .animation(.easeOut(duration: 0.38).delay(0.10), value: appear)
    }

    // MARK: - Mastery Breakdown

    private var masteryBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mastery")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
                .kerning(1.2)

            ForEach(MasteryLevel.allCases, id: \.self) { level in
                let count = store.words.filter { $0.masteryLevel == level }.count
                MasteryRow(level: level, count: count, total: store.totalWords)
            }
        }
        .padding(.bottom, 28)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 10)
        .animation(.easeOut(duration: 0.38).delay(0.14), value: appear)
    }

    // MARK: - Streak

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Streak")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
                .kerning(1.2)

            HStack(spacing: 0) {
                BigStat(value: "\(store.currentStreak)", label: "Current")
                Spacer()
                BigStat(value: "\(store.longestStreak)", label: "Best")
                Spacer()
                BigStat(value: "\(store.dailyGoal)", label: "Daily Goal")
            }
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 10)
        .animation(.easeOut(duration: 0.38).delay(0.18), value: appear)
    }
}

// MARK: - Big Stat

private struct BigStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(AppTheme.text)
                .monospacedDigit()
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
                .kerning(0.8)
        }
    }
}

// MARK: - Mastery Row

private struct MasteryRow: View {
    let level: MasteryLevel
    let count: Int
    let total: Int

    private var fraction: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }

    private var dotColor: Color {
        switch level {
        case .new:       return AppTheme.border
        case .learning:  return CardPalette.skyBlue
        case .reviewing: return CardPalette.peach
        case .mastered:  return CardPalette.mint
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Dot indicator
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)

            // Label
            Text(level.rawValue)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppTheme.text)
                .frame(width: 80, alignment: .leading)

            // Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.separator)
                        .frame(height: 3)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(dotColor)
                        .frame(width: geo.size.width * fraction, height: 3)
                        .animation(.easeOut(duration: 0.5), value: fraction)
                }
            }
            .frame(height: 3)

            // Count
            Text("\(count)")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 28, alignment: .trailing)
        }
    }
}
