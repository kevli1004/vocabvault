import SwiftUI

// MARK: - Minimal Card
// A clean, paper-like surface card with subtle border and optional shadow.
// Replaces the old glassmorphism GlassCard.

struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: CGFloat
    var opacity: Double = 1.0     // legacy param, ignored in new design
    let content: Content

    init(
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 20,
        opacity: Double = 1.0,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.opacity = opacity
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(AppTheme.border, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Category Badge (editorial pill style)

struct CategoryBadge: View {
    let category: WordCategory

    var body: some View {
        HStack(spacing: 4) {
            Text(category.emoji)
                .font(.system(size: 11))
            Text(category.rawValue.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .kerning(0.8)
        }
        .foregroundColor(AppTheme.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
    }
}

// MARK: - Card Category Badge (for use on colored card backgrounds)

struct CardCategoryBadge: View {
    let category: WordCategory

    var body: some View {
        HStack(spacing: 4) {
            Text(category.emoji)
                .font(.system(size: 11))
            Text(category.rawValue.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .kerning(0.8)
        }
        .foregroundColor(CardPalette.cardText.opacity(0.6))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.35))
        )
    }
}

// MARK: - Mastery Badge (minimal dot indicator)

struct MasteryBadge: View {
    let level: MasteryLevel

    private var label: String {
        switch level {
        case .new:       return "New"
        case .learning:  return "Learning"
        case .reviewing: return "Reviewing"
        case .mastered:  return "Mastered"
        }
    }

    private var dotColor: Color {
        switch level {
        case .new:       return AppTheme.textTertiary
        case .learning:  return CardPalette.skyBlue
        case .reviewing: return CardPalette.peach
        case .mastered:  return CardPalette.mint
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .strokeBorder(AppTheme.border, lineWidth: 1)
        )
    }
}

// MARK: - Difficulty Indicator (three minimal dots)

struct DifficultyDots: View {
    let difficulty: Int  // 1–3

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...3, id: \.self) { i in
                Circle()
                    .fill(i <= difficulty ? AppTheme.text : AppTheme.border)
                    .frame(width: 5, height: 5)
            }
        }
    }
}

// MARK: - Minimal Section Header

struct MinimalSectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
                .kerning(1.2)

            Spacer()

            if let action, let onAction {
                Button(action: onAction) {
                    Text(action)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }
}

// MARK: - Thin Divider

struct MinimalDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppTheme.separator)
            .frame(height: 1)
    }
}
