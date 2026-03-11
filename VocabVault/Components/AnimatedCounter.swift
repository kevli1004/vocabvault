import SwiftUI

// MARK: - Animated Counter

struct AnimatedCounter: View {
    let value: Int
    let label: String
    var fontSize: CGFloat = 36

    @State private var displayValue: Int = 0

    var body: some View {
        VStack(spacing: 4) {
            Text("\(displayValue)")
                .font(.system(size: fontSize, weight: .bold, design: .default))
                .foregroundColor(AppTheme.text)
                .monospacedDigit()
                .contentTransition(.numericText())

            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
                .kerning(1.0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                displayValue = value
            }
        }
        .onChange(of: value) { newValue in
            withAnimation(.easeOut(duration: 0.4)) {
                displayValue = newValue
            }
        }
    }
}

// MARK: - Progress Ring (minimal, for quiz results)

struct ProgressRing: View {
    let progress: Double        // 0.0 – 1.0
    var lineWidth: CGFloat = 6
    var ringColor: Color = AppTheme.text
    var showLabel: Bool = true
    var trackColor: Color = AppTheme.border

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            // Fill
            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.7), value: progress)

            if showLabel {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.text)
            }
        }
    }
}

// MARK: - Thin Progress Bar (for session progress indicator)

struct ThinProgressBar: View {
    let current: Int
    let total: Int
    var height: CGFloat = 2

    private var fraction: Double {
        total > 0 ? Double(current) / Double(total) : 0
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(AppTheme.border)
                    .frame(height: height)

                Rectangle()
                    .fill(AppTheme.text)
                    .frame(width: geo.size.width * fraction, height: height)
                    .animation(.easeOut(duration: 0.3), value: fraction)
            }
        }
        .frame(height: height)
    }
}
