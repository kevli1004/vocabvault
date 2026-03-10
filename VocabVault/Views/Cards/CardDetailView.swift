import SwiftUI

// MARK: - Card Detail View (full-screen word detail)

struct CardDetailView: View {
    let word: Word
    @EnvironmentObject var store: WordStore
    @Environment(\.dismiss) var dismiss

    @State private var appear = false

    var body: some View {
        let (c1, c2) = Color.categoryGradient(word.category)

        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.06, blue: 0.14),
                    Color(red: 0.05, green: 0.04, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Accent blob
            Circle()
                .fill(c1.opacity(0.15))
                .frame(width: 400)
                .offset(x: 100, y: -200)
                .blur(radius: 80)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header card
                    ZStack {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [c1, c2],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        ShimmerOverlay()
                            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1.5)

                        VStack(spacing: 12) {
                            HStack {
                                CategoryBadge(category: word.category)
                                Spacer()
                                DifficultyDots(difficulty: word.difficulty)
                                MasteryBadge(level: word.masteryLevel)
                            }

                            Spacer()

                            Text(word.word)
                                .font(.system(size: 52, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .shadow(color: .black.opacity(0.2), radius: 8)

                            Spacer()

                            // Stats row
                            HStack(spacing: 20) {
                                MiniStat(label: "Correct", value: "\(word.timesCorrect)", icon: "checkmark.circle")
                                MiniStat(label: "Practiced", value: "\(word.timesIncorrect)", icon: "arrow.clockwise")
                                MiniStat(label: "Accuracy", value: word.timesCorrect + word.timesIncorrect > 0 ? "\(Int(word.accuracyRate * 100))%" : "—", icon: "percent")
                            }
                        }
                        .padding(28)
                    }
                    .frame(height: 280)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .scaleEffect(appear ? 1 : 0.92)
                    .opacity(appear ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: appear)

                    // Content sections
                    VStack(spacing: 16) {
                        DetailSection(icon: "text.alignleft", title: "Definition", content: word.definition, accentColor: c1)
                        DetailSection(icon: "quote.bubble.fill", title: "Example Sentence", content: word.exampleSentence, accentColor: Color.gradTeal1)

                        // Synonyms
                        GlassCard(cornerRadius: 20, padding: 18) {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(icon: "arrow.triangle.2.circlepath", title: "Synonyms", accentColor: Color.gradMint1)
                                HStack(spacing: 10) {
                                    ForEach(word.synonyms, id: \.self) { syn in
                                        Text(syn)
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule().fill(Color.gradMint1.opacity(0.2))
                                            )
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.easeOut(duration: 0.4).delay(0.15), value: appear)

                        DetailSection(icon: "globe.europe.africa.fill", title: "Etymology", content: word.etymology, accentColor: Color.gradAmber1)
                        DetailSection(icon: "lightbulb.fill", title: "Memory Aid", content: word.mnemonic, accentColor: Color.gradRose1)

                        // Spaced repetition info
                        GlassCard(cornerRadius: 20, padding: 18) {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(icon: "brain.filled.head.profile", title: "Spaced Repetition", accentColor: Color.gradLav1)
                                HStack(spacing: 16) {
                                    SRStat(label: "Interval", value: "\(word.interval)d")
                                    SRStat(label: "Repetitions", value: "\(word.repetitions)")
                                    SRStat(label: "Ease", value: String(format: "%.1f", word.easeFactor))
                                    SRStat(label: "Due", value: dueDateString)
                                }
                            }
                        }
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.easeOut(duration: 0.4).delay(0.25), value: appear)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }

            // Navigation bar
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }

                    Spacer()

                    Button {
                        store.toggleFavorite(wordId: word.id)
                    } label: {
                        Image(systemName: word.isFavorite ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(word.isFavorite ? .swipeFav : .white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                appear = true
            }
        }
    }

    private var dueDateString: String {
        if word.isDueForReview { return "Now" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: word.nextReviewDate).day ?? 0
        return "\(days)d"
    }
}

// MARK: - Detail Section

private struct DetailSection: View {
    let icon: String
    let title: String
    let content: String
    let accentColor: Color

    @State private var appear = false

    var body: some View {
        GlassCard(cornerRadius: 20, padding: 18) {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(icon: icon, title: title, accentColor: accentColor)
                Text(content)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                appear = true
            }
        }
    }
}

private struct SectionHeader: View {
    let icon: String
    let title: String
    let accentColor: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(accentColor)
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(accentColor.opacity(0.8))
                .kerning(1.2)
        }
    }
}

private struct MiniStat: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

private struct SRStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }
}
