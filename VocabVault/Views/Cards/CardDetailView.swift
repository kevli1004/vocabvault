import SwiftUI

// MARK: - Card Detail View
// Clean, editorial full-screen word detail. Cream background, typography-first.

struct CardDetailView: View {
    let word: Word
    @EnvironmentObject var store: WordStore
    @Environment(\.dismiss) var dismiss

    @State private var appear = false

    private var cardColor: Color { CardPalette.color(for: word.category) }

    var body: some View {
        ZStack(alignment: .top) {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero header (colorful top block)
                    heroHeader

                    // Content sections
                    contentBody
                        .padding(.horizontal, 28)
                        .padding(.bottom, 60)
                }
            }

            // Navigation overlay
            navigationBar
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.38)) { appear = true }
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            // Solid pastel block
            cardColor
                .frame(height: 260)
                .ignoresSafeArea(edges: .top)

            VStack(alignment: .leading, spacing: 10) {
                // Category + difficulty
                HStack(spacing: 10) {
                    CardCategoryBadge(category: word.category)
                    Spacer()
                    DifficultyDots(difficulty: word.difficulty)
                        .opacity(0.65)
                    MasteryBadge(level: word.masteryLevel)
                }

                Spacer()

                // Word
                Text(word.word)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(CardPalette.cardText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                // Category as italic subtitle
                Text(word.category.rawValue.lowercased())
                    .font(.system(size: 15, weight: .regular))
                    .italic()
                    .foregroundColor(CardPalette.cardText.opacity(0.50))
            }
            .padding(.horizontal, 28)
            .padding(.top, 80) // clear nav bar
            .padding(.bottom, 24)
        }
        .frame(height: 260)
        .scaleEffect(appear ? 1 : 0.96, anchor: .top)
        .opacity(appear ? 1 : 0)
    }

    // MARK: - Content Body

    private var contentBody: some View {
        VStack(alignment: .leading, spacing: 28) {
            // Accuracy stats row
            statsRow
                .padding(.top, 28)

            MinimalDivider()

            // Definition
            DetailSection(label: "Definition") {
                Text(word.definition)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(AppTheme.text)
                    .lineSpacing(4)
            }

            MinimalDivider()

            // Example
            DetailSection(label: "Example") {
                Text(""\(word.exampleSentence)"")
                    .font(.system(size: 16, weight: .regular))
                    .italic()
                    .foregroundColor(AppTheme.textSecondary)
                    .lineSpacing(4)
            }

            MinimalDivider()

            // Synonyms
            if !word.synonyms.isEmpty {
                DetailSection(label: "Synonyms") {
                    HStack(spacing: 8) {
                        ForEach(word.synonyms, id: \.self) { syn in
                            Text(syn)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.text)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .strokeBorder(AppTheme.border, lineWidth: 1)
                                )
                        }
                        Spacer()
                    }
                }
                MinimalDivider()
            }

            // Etymology
            DetailSection(label: "Etymology") {
                Text(word.etymology)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineSpacing(3)
            }

            MinimalDivider()

            // Memory aid
            DetailSection(label: "Memory Aid") {
                Text(word.mnemonic)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineSpacing(3)
            }

            MinimalDivider()

            // Spaced repetition
            srSection
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 16)
        .animation(.easeOut(duration: 0.38).delay(0.12), value: appear)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            StatCell(
                value: "\(word.timesCorrect)",
                label: "Correct"
            )
            Spacer()
            StatCell(
                value: word.timesCorrect + word.timesIncorrect > 0
                    ? "\(Int(word.accuracyRate * 100))%"
                    : "—",
                label: "Accuracy"
            )
            Spacer()
            StatCell(
                value: "\(word.repetitions)",
                label: "Reviews"
            )
            Spacer()
            StatCell(
                value: word.isDueForReview ? "Now" : "\(daysUntilReview)d",
                label: "Due"
            )
        }
    }

    // MARK: - SR Section

    private var srSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SPACED REPETITION")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
                .kerning(1.2)

            HStack(spacing: 0) {
                StatCell(value: "\(word.interval)d",  label: "Interval")
                Spacer()
                StatCell(value: "\(word.repetitions)", label: "Reps")
                Spacer()
                StatCell(value: String(format: "%.1f", word.easeFactor), label: "Ease")
                Spacer()
                StatCell(value: word.isDueForReview ? "Now" : "\(daysUntilReview)d", label: "Next")
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(CardPalette.cardText)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.35)))
            }
            .buttonStyle(.plain)

            Spacer()

            Button { store.toggleFavorite(wordId: word.id) } label: {
                Image(systemName: word.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(word.isFavorite ? CardPalette.dustyRose : CardPalette.cardText)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.35)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 52)
    }

    // MARK: - Helpers

    private var daysUntilReview: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: word.nextReviewDate).day ?? 0)
    }
}

// MARK: - Detail Section

private struct DetailSection<C: View>: View {
    let label: String
    let content: C

    init(label: String, @ViewBuilder content: () -> C) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
                .kerning(1.2)
            content
        }
    }
}

// MARK: - Stat Cell

private struct StatCell: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.text)
                .monospacedDigit()
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
                .kerning(0.8)
        }
    }
}
