import SwiftUI

// MARK: - Settings View (cream editorial)

struct SettingsView: View {
    @EnvironmentObject var store: WordStore
    @State private var dailyGoalInput: Double = 20
    @State private var showResetConfirm = false
    @State private var showResetSuccess = false
    @AppStorage("vv_notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("vv_notificationHour")    private var notificationHour = 9
    @State private var appear = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    header
                        .padding(.horizontal, 28)
                        .padding(.top, 64)
                        .padding(.bottom, 32)

                    MinimalDivider()

                    // Daily Goal
                    dailyGoalSection
                        .padding(.horizontal, 28)
                        .padding(.vertical, 24)

                    MinimalDivider()

                    // Notifications
                    notificationSection
                        .padding(.horizontal, 28)
                        .padding(.vertical, 20)

                    MinimalDivider()

                    // Stats overview
                    statsSection
                        .padding(.horizontal, 28)
                        .padding(.vertical, 24)

                    MinimalDivider()

                    // About
                    aboutSection
                        .padding(.horizontal, 28)
                        .padding(.vertical, 24)

                    MinimalDivider()

                    // Danger zone
                    dangerZone
                        .padding(.horizontal, 28)
                        .padding(.vertical, 24)

                    Spacer(minLength: 80)
                }
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
                    withAnimation { showResetSuccess = false }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all progress, streaks, and mastery levels. Cannot be undone.")
        }
        .overlay(alignment: .top) {
            if showResetSuccess {
                SuccessToast(message: "Progress reset. Fresh start.")
                    .padding(.top, 56)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: showResetSuccess)
            }
        }
        .onAppear {
            dailyGoalInput = Double(store.dailyGoal)
            withAnimation(.easeOut(duration: 0.38)) { appear = true }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Settings")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(AppTheme.text)
            Spacer()
            Text("v1.0")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
        }
        .opacity(appear ? 1 : 0)
    }

    // MARK: - Daily Goal

    private var dailyGoalSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Study Goal")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
                .kerning(1.2)

            HStack {
                Text("Daily target")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppTheme.text)
                Spacer()
                Text("\(Int(dailyGoalInput)) words")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(AppTheme.text)
            }

            Slider(value: $dailyGoalInput, in: 5...50, step: 5) { _ in
                store.setDailyGoal(Int(dailyGoalInput))
            }
            .tint(AppTheme.text)

            HStack {
                Text("5")
                Spacer()
                Text("25")
                Spacer()
                Text("50")
            }
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(AppTheme.textTertiary)
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.38).delay(0.04), value: appear)
    }

    // MARK: - Notifications

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reminders")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
                .kerning(1.2)

            Toggle(isOn: $notificationsEnabled) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Daily reminder")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.text)
                    Text("Get reminded to study each day")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            .tint(AppTheme.text)

            if notificationsEnabled {
                HStack {
                    Text("Reminder time")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.text)
                    Spacer()
                    Picker("Hour", selection: $notificationHour) {
                        ForEach(6..<23, id: \.self) { hour in
                            Text(hourString(hour))
                                .tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.text)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: notificationsEnabled)
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.38).delay(0.06), value: appear)
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Stats")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
                .kerning(1.2)

            VStack(spacing: 12) {
                SettingsRow(label: "Current Streak", value: "\(store.currentStreak) days")
                SettingsRow(label: "Longest Streak", value: "\(store.longestStreak) days")
                SettingsRow(label: "Total Reviews",  value: "\(store.totalReviews)")
                SettingsRow(label: "Accuracy",       value: "\(Int(store.overallAccuracy * 100))%")
                SettingsRow(label: "Words Mastered", value: "\(store.totalMastered) / \(store.totalWords)")
            }
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.38).delay(0.08), value: appear)
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
                .kerning(1.2)

            VStack(spacing: 12) {
                SettingsRow(label: "App",       value: "VocabVault")
                SettingsRow(label: "Words",     value: "\(store.totalWords)")
                SettingsRow(label: "Algorithm", value: "SM-2 Spaced Repetition")
                SettingsRow(label: "Platform",  value: "iOS 17+")
            }
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.38).delay(0.10), value: appear)
    }

    // MARK: - Danger Zone

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Data")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
                .kerning(1.2)

            Button {
                showResetConfirm = true
            } label: {
                HStack {
                    Text("Reset All Progress")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.error)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.error.opacity(0.5))
                }
            }
            .buttonStyle(.plain)

            Text("Permanently deletes all study progress, streaks, and mastery levels. Your word list is preserved.")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textTertiary)
                .lineSpacing(2)
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.38).delay(0.12), value: appear)
    }

    // MARK: - Helpers

    private func hourString(_ hour: Int) -> String {
        let h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        let suffix = hour >= 12 ? "PM" : "AM"
        return "\(h):00 \(suffix)"
    }
}

// MARK: - Settings Row

private struct SettingsRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.text)
        }
    }
}

// MARK: - Success Toast

private struct SuccessToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.success)
                .frame(width: 24, height: 24)
                .background(Circle().fill(AppTheme.success.opacity(0.12)))

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.text)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}
