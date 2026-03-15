import SwiftUI

// MARK: - Card Detail View
// Full-screen push. Color header + content. No stats, no SR section, no nav circles.

struct CardDetailView: View {
    let word: Word
    @Environment(\.dismiss) var dismiss

    @State private var appear = false

    private var cardColor: Color { CardPalette.color(for: word.category) }

    var body: some View {
        ZStack(alignment: .top) {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroHeader
                    contentBody
                        .padding(.horizontal, 28)
                        .padding(.bottom, 60)
                }
            }

            // Back chevron
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(CardPalette.cardText)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 52)
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.38)) { appear = true }
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            cardColor
                .frame(height: 240)
                .ignoresSafeArea(edges: .top)

            VStack(alignment: .leading, spacing: 8) {
                Spacer()

                Text(word.word)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(CardPalette.cardText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text(word.category.rawValue.lowercased())
                    .font(.system(size: 15, weight: .regular))
                    .italic()
                    .foregroundColor(CardPalette.cardText.opacity(0.50))
            }
            .padding(.horizontal, 28)
            .padding(.top, 80)
            .padding(.bottom, 24)
        }
        .frame(height: 240)
        .opacity(appear ? 1 : 0)
    }

    // MARK: - Content Body

    private var contentBody: some View {
        VStack(alignment: .leading, spacing: 28) {
            // Definition
            VStack(alignment: .leading, spacing: 10) {
                Text(word.definition)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(AppTheme.text)
                    .lineSpacing(4)
            }
            .padding(.top, 28)

            MinimalDivider()

            // Example
            Text(""\(word.exampleSentence)"")
                .font(.system(size: 16, weight: .regular))
                .italic()
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(4)

            MinimalDivider()

            // Synonyms
            if !word.synonyms.isEmpty {
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
                MinimalDivider()
            }

            // Etymology
            Text(word.etymology)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(3)

            MinimalDivider()

            // Memory aid
            Text(word.mnemonic)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(3)
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 16)
        .animation(.easeOut(duration: 0.38).delay(0.12), value: appear)
    }
}
