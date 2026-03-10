import SwiftUI

// MARK: - Animated Counter

struct AnimatedCounter: View {
    let value: Int
    var font: Font = .system(size: 32, weight: .bold, design: .rounded)
    var color: Color = .white
    var prefix: String = ""
    var suffix: String = ""

    @State private var displayValue: Int = 0
    @State private var previousValue: Int = 0

    var body: some View {
        HStack(spacing: 0) {
            if !prefix.isEmpty {
                Text(prefix)
                    .font(font)
                    .foregroundColor(color)
            }

            Text("\(displayValue)")
                .font(font)
                .foregroundColor(color)
                .contentTransition(.numericText(value: Double(displayValue)))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: displayValue)

            if !suffix.isEmpty {
                Text(suffix)
                    .font(font)
                    .foregroundColor(color)
            }
        }
        .onAppear { animateTo(value) }
        .onChange(of: value) { _, newValue in animateTo(newValue) }
    }

    private func animateTo(_ target: Int) {
        let step = target > displayValue ? 1 : -1
        let range = abs(target - displayValue)

        if range <= 1 {
            withAnimation { displayValue = target }
            return
        }

        // For larger jumps, animate in chunks
        let duration = min(Double(range) * 0.02, 0.8)
        withAnimation(.easeOut(duration: duration)) {
            displayValue = target
        }
    }
}

// MARK: - Streak Counter

struct StreakCounter: View {
    let streak: Int
    @State private var showBurst = false

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 28))
                        .scaleEffect(showBurst ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: showBurst)

                    AnimatedCounter(
                        value: streak,
                        font: .system(size: 28, weight: .black, design: .rounded)
                    )
                }

                Text("day streak")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }

            if showBurst {
                BurstEffect(color: .gradAmber1)
                    .transition(.opacity)
            }
        }
        .onChange(of: streak) { _, newStreak in
            if newStreak > 0 {
                showBurst = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showBurst = false
                }
            }
        }
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double  // 0...1
    let lineWidth: CGFloat
    var ringColor: Color = .gradPurple1
    var trackColor: Color = .white.opacity(0.15)
    var showLabel: Bool = true

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            // Progress
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [ringColor, ringColor.opacity(0.5)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)

            if showLabel {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Mini Bar Chart

struct MiniBarChart: View {
    let values: [Int]
    let labels: [String]
    var accentColor: Color = .gradPurple1

    private var maxValue: Int { values.max() ?? 1 }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(values.enumerated()), id: \.offset) { idx, value in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            value == maxValue
                                ? LinearGradient(colors: [accentColor, accentColor.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [Color.white.opacity(0.25), Color.white.opacity(0.15)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(height: barHeight(for: value))
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(idx) * 0.05), value: value)

                    if idx < labels.count {
                        Text(labels[idx])
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
    }

    private func barHeight(for value: Int) -> CGFloat {
        let maxHeight: CGFloat = 60
        guard maxValue > 0 else { return 4 }
        return max(4, CGFloat(value) / CGFloat(maxValue) * maxHeight)
    }
}
