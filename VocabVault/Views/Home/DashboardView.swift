import SwiftUI

// MARK: - Dashboard / Stats View
// Four numbers. That's it.

struct DashboardView: View {
    @EnvironmentObject var store: WordStore
    @State private var appear = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Four numbers — the only content
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 48) {
                    bigStat(value: "\(store.totalWords)", label: "WORDS")
                    bigStat(value: "\(store.totalMastered)", label: "MASTERED")
                    bigStat(value: "\(Int(store.overallAccuracy * 100))%", label: "ACCURACY")
                    bigStat(value: "\(store.currentStreak)", label: "STREAK")
                }
                .padding(.horizontal, 48)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 12)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) { appear = true }
        }
    }

    private func bigStat(value: String, label: String) -> some View {
        VStack(alignment: .center, spacing: 6) {
            Text(value)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(AppTheme.text)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
                .kerning(1.2)
        }
    }
}
