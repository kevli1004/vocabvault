import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {
    @EnvironmentObject var store: WordStore
    @Binding var selectedTab: AppTab

    @State private var appear = false
    @State private var greetingOpacity: Double = 0

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default:       return "Burning midnight oil"
        }
    }

    private var greetingEmoji: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "☀️"
        case 12..<17: return "🌤"
        case 17..<21: return "🌇"
        default:       return "🌙"
        }
    }

    private var motivationalQuote: String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return motivationalQuotes[dayOfYear % motivationalQuotes.count]
    }

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Greeting
                    greetingSection
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    // Review CTA card
                    if store.dueCount > 0 {
                        reviewCTACard
                            .padding(.horizontal, 20)
                    }

                    // Stats grid
                    statsGrid
                        .padding(.horizontal, 20)

                    // Streak & Progress
                    streakCard
                        .padding(.horizontal, 20)

                    // Weekly bar chart
                    weeklyProgressCard
                        .padding(.horizontal, 20)

                    // Category breakdown
                    categoryBreakdownCard
                        .padding(.horizontal, 20)

                    // Quote
                    quoteCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appear = true
                greetingOpacity = 1
            }
        }
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(greetingEmoji)
                            .font(.system(size: 24))
                        Text(greeting)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Text("VocabVault")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()

                // Streak display
                GlassCard(cornerRadius: 16, padding: 12, opacity: 0.12) {
                    StreakCounter(streak: store.currentStreak)
                }
            }
        }
        .opacity(greetingOpacity)
        .offset(y: appear ? 0 : -20)
        .animation(.easeOut(duration: 0.5), value: appear)
    }

    // MARK: - Review CTA

    private var reviewCTACard: some View {
        Button {
            selectedTab = .cards
        } label: {
            GlassCard(cornerRadius: 24, padding: 0, opacity: 0.08) {
                HStack(spacing: 0) {
                    // Left gradient stripe
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(LinearGradient.pastelGradient(for: .teal))
                        .frame(width: 6)
                        .padding(.vertical, 0)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text("📚")
                                .font(.system(size: 22))
                            Text("Ready to Review")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }

                        Text("\(store.dueCount) words due · \(store.newCount) new")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.gradTeal1)
                        .padding(.trailing, 20)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
        .bouncyAppear(delay: 0.1)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            StatCard(
                title: "Words Mastered",
                value: "\(store.totalMastered)",
                subtitle: "of \(store.totalWords) total",
                icon: "star.fill",
                palette: .amber
            )
            .bouncyAppear(delay: 0.15)

            StatCard(
                title: "Total Reviews",
                value: "\(store.totalReviews)",
                subtitle: nil,
                icon: "arrow.clockwise",
                palette: .teal
            )
            .bouncyAppear(delay: 0.20)

            StatCard(
                title: "Accuracy",
                value: "\(Int(store.overallAccuracy * 100))%",
                subtitle: "all-time",
                icon: "target",
                palette: .coral
            )
            .bouncyAppear(delay: 0.25)

            StatCard(
                title: "Today's Goal",
                value: "\(store.reviewedToday)/\(store.dailyGoal)",
                subtitle: "words reviewed",
                icon: "checkmark.circle.fill",
                palette: .mint
            )
            .bouncyAppear(delay: 0.30)
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        GlassCard(cornerRadius: 24, padding: 20, opacity: 0.1) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Progress")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Text("Longest: \(store.longestStreak) days")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }

                // Mastery breakdown
                HStack(spacing: 0) {
                    ForEach(store.masteryBreakdown, id: \.0) { level, count in
                        let fraction = store.totalWords > 0 ? Double(count) / Double(store.totalWords) : 0
                        Rectangle()
                            .fill(Color.masteryColor(level))
                            .frame(width: max(0, (UIScreen.main.bounds.width - 80) * fraction))
                            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1), value: fraction)
                    }
                }
                .frame(height: 8)
                .clipShape(Capsule())

                // Legend
                HStack(spacing: 16) {
                    ForEach(MasteryLevel.allCases, id: \.self) { level in
                        let count = store.masteryBreakdown.first(where: { $0.0 == level })?.1 ?? 0
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.masteryColor(level))
                                .frame(width: 8, height: 8)
                            Text(level.rawValue)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                            Text("(\(count))")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.45))
                        }
                    }
                    Spacer()
                }
            }
        }
        .bouncyAppear(delay: 0.35)
    }

    // MARK: - Weekly Progress

    private var weeklyProgressCard: some View {
        GlassCard(cornerRadius: 24, padding: 20, opacity: 0.1) {
            VStack(alignment: .leading, spacing: 16) {
                Text("This Week")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                MiniBarChart(
                    values: store.weeklyProgress,
                    labels: weekdayLabels(),
                    accentColor: .gradPurple1
                )
                .frame(height: 80)
            }
        }
        .bouncyAppear(delay: 0.40)
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownCard: some View {
        GlassCard(cornerRadius: 24, padding: 20, opacity: 0.1) {
            VStack(alignment: .leading, spacing: 14) {
                Text("By Category")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                ForEach(store.categoryBreakdown, id: \.0) { category, total in
                    let mastered = store.words(in: category).filter { $0.masteryLevel == .mastered }.count
                    let fraction = total > 0 ? Double(mastered) / Double(total) : 0
                    let (c1, _) = Color.categoryGradient(category)

                    HStack(spacing: 12) {
                        Text(category.emoji)
                            .font(.system(size: 18))
                            .frame(width: 30)

                        Text(category.rawValue)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 85, alignment: .leading)

                        // Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color.white.opacity(0.1))
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(c1)
                                    .frame(width: geo.size.width * fraction)
                                    .animation(.spring(response: 0.7).delay(0.05), value: fraction)
                            }
                        }
                        .frame(height: 6)

                        Text("\(mastered)/\(total)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.45))
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }
        }
        .bouncyAppear(delay: 0.45)
    }

    // MARK: - Quote Card

    private var quoteCard: some View {
        GlassCard(cornerRadius: 24, padding: 22, opacity: 0.08) {
            VStack(spacing: 10) {
                Text("💡")
                    .font(.system(size: 28))
                Text("\"\(motivationalQuote)\"")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .italic()
            }
            .frame(maxWidth: .infinity)
        }
        .bouncyAppear(delay: 0.50)
    }

    // MARK: - Helpers

    private func weekdayLabels() -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return (0..<7).map { daysAgo in
            let date = Calendar.current.date(byAdding: .day, value: -(6 - daysAgo), to: Date()) ?? Date()
            return formatter.string(from: date)
        }
    }

    private let motivationalQuotes: [String] = [
        "The limits of my language mean the limits of my world. — Wittgenstein",
        "One language sets you in a corridor for life. Two languages open every door along the way. — Frank Smith",
        "Learn a language and you'll avoid a war. — Arab proverb",
        "The more languages you know, the more you are human. — Tomáš Masaryk",
        "You can never understand one language until you understand at least two. — Geoffrey Willans",
        "A different language is a different vision of life. — Federico Fellini",
        "Words are, of course, the most powerful drug used by mankind. — Rudyard Kipling",
        "Every word was once a poem. — Ralph Waldo Emerson",
        "The pen is mightier than the sword. — Edward Bulwer-Lytton",
        "In the beginning was the Word. — John 1:1",
        "Vocabulary is the one area of verbal intelligence that you can improve the most in the least time. — Unknown",
        "The difference between the right word and the almost right word is the difference between lightning and a lightning bug. — Mark Twain",
        "Words can inspire, words can destroy. Choose yours carefully. — Robin Sharma",
        "Words are a lens to focus one's mind. — Ayn Rand",
        "Language is the dress of thought. — Samuel Johnson"
    ]
}
