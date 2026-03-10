import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var store: WordStore
    @State private var dailyGoalInput: Double = 20
    @State private var showResetConfirm = false
    @State private var showResetSuccess = false
    @AppStorage("vv_notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("vv_notificationHour")    private var notificationHour = 9

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    settingsHeader

                    // Daily Goal
                    dailyGoalSection

                    // Notification settings
                    notificationSection

                    // App info
                    aboutSection

                    // Stats overview
                    statsSection

                    // Danger zone
                    dangerZone

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .confirmationDialog(
            "Reset All Progress?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset Everything", role: .destructive) {
                store.resetProgress()
                showResetSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showResetSuccess = false
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all your progress, streaks, and mastery levels. This cannot be undone.")
        }
        .overlay(alignment: .top) {
            if showResetSuccess {
                SuccessToast(message: "Progress reset. Fresh start! 🌱")
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: showResetSuccess)
            }
        }
        .onAppear {
            dailyGoalInput = Double(store.dailyGoal)
        }
    }

    // MARK: - Header

    private var settingsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("Version 1.0")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            Text("⚙️")
                .font(.system(size: 36))
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Daily Goal

    private var dailyGoalSection: some View {
        GlassCard(cornerRadius: 24, padding: 22, opacity: 0.1) {
            VStack(alignment: .leading, spacing: 18) {
                SettingsSectionHeader(title: "Study Goal", icon: "target", color: .gradCoral1)

                VStack(spacing: 12) {
                    HStack {
                        Text("Daily word target")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(dailyGoalInput)) words")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(.gradCoral1)
                    }

                    Slider(
                        value: $dailyGoalInput,
                        in: 5...50,
                        step: 5
                    ) { _ in
                        store.setDailyGoal(Int(dailyGoalInput))
                    }
                    .tint(.gradCoral1)

                    HStack {
                        Text("5")
                        Spacer()
                        Text("25")
                        Spacer()
                        Text("50")
                    }
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
                }
            }
        }
    }

    // MARK: - Notifications

    private var notificationSection: some View {
        GlassCard(cornerRadius: 24, padding: 22, opacity: 0.1) {
            VStack(alignment: .leading, spacing: 18) {
                SettingsSectionHeader(title: "Reminders", icon: "bell.badge.fill", color: .gradAmber1)

                Toggle(isOn: $notificationsEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily reminder")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Get reminded to study each day")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .tint(.gradAmber1)

                if notificationsEnabled {
                    HStack {
                        Text("Reminder time")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        Picker("Hour", selection: $notificationHour) {
                            ForEach(6..<23, id: \.self) { hour in
                                Text(hourString(hour))
                                    .tag(hour)
                                    .foregroundColor(.white)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.gradAmber1)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        GlassCard(cornerRadius: 24, padding: 22, opacity: 0.1) {
            VStack(alignment: .leading, spacing: 18) {
                SettingsSectionHeader(title: "About", icon: "info.circle.fill", color: .gradPurple1)

                VStack(spacing: 12) {
                    AboutRow(label: "App", value: "VocabVault")
                    AboutRow(label: "Words", value: "\(store.totalWords)")
                    AboutRow(label: "Algorithm", value: "SM-2 Spaced Repetition")
                    AboutRow(label: "Platform", value: "iOS 17+")
                }
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        GlassCard(cornerRadius: 24, padding: 22, opacity: 0.1) {
            VStack(alignment: .leading, spacing: 18) {
                SettingsSectionHeader(title: "Your Stats", icon: "chart.bar.fill", color: .gradMint1)

                VStack(spacing: 12) {
                    AboutRow(label: "Current Streak", value: "\(store.currentStreak) days 🔥")
                    AboutRow(label: "Longest Streak", value: "\(store.longestStreak) days")
                    AboutRow(label: "Total Reviews", value: "\(store.totalReviews)")
                    AboutRow(label: "Accuracy", value: "\(Int(store.overallAccuracy * 100))%")
                    AboutRow(label: "Words Mastered", value: "\(store.totalMastered) / \(store.totalWords)")
                }
            }
        }
    }

    // MARK: - Danger Zone

    private var dangerZone: some View {
        GlassCard(cornerRadius: 24, padding: 22, opacity: 0.1) {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeader(title: "Danger Zone", icon: "exclamationmark.triangle.fill", color: .swipeLeft)

                Button {
                    showResetConfirm = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 18))
                        Text("Reset All Progress")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.swipeLeft.opacity(0.5))
                    }
                    .foregroundColor(.swipeLeft)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.swipeLeft.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.swipeLeft.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                Text("This will permanently delete all study progress, streaks, and mastery levels. Your word list will remain.")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
    }

    // MARK: - Helpers

    private func hourString(_ hour: Int) -> String {
        let h = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour
        let suffix = hour >= 12 ? "PM" : "AM"
        return "\(h):00 \(suffix)"
    }
}

// MARK: - Settings Section Header

private struct SettingsSectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(color.opacity(0.8))
                .kerning(1.2)
        }
    }
}

// MARK: - About Row

private struct AboutRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Success Toast

private struct SuccessToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.gradMint1)
            Text(message)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 20)
    }
}
