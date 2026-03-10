import SwiftUI

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 20
    var opacity: Double = 0.15
    var shadowRadius: CGFloat = 16
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(opacity))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: shadowRadius, x: 0, y: 8)
    }
}

// MARK: - Dark Glass Card

struct DarkGlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 20
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let palette: GradientPalette
    var isLarge: Bool = false

    var body: some View {
        GlassCard(cornerRadius: 20, padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient.pastelGradient(for: palette)
                            )
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }

                Text(value)
                    .font(.system(size: isLarge ? 32 : 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }
}

// MARK: - Category Badge

struct CategoryBadge: View {
    let category: WordCategory

    var body: some View {
        let (c1, _) = Color.categoryGradient(category)
        HStack(spacing: 4) {
            Text(category.emoji)
                .font(.system(size: 12))
            Text(category.rawValue)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(c1.opacity(0.85))
        )
    }
}

// MARK: - Mastery Badge

struct MasteryBadge: View {
    let level: MasteryLevel

    var body: some View {
        Text(level.rawValue)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.masteryColor(level))
            )
    }
}

// MARK: - Difficulty Dots

struct DifficultyDots: View {
    let difficulty: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...3, id: \.self) { dot in
                Circle()
                    .fill(dot <= difficulty ? dotColor : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var dotColor: Color {
        switch difficulty {
        case 1: return Color.gradMint1
        case 2: return Color.gradAmber1
        default: return Color.gradCoral1
        }
    }
}
