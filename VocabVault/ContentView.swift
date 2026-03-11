import SwiftUI

// MARK: - Content View (Root)

struct ContentView: View {
    @StateObject private var store = WordStore()
    @State private var selectedTab: AppTab = .practice

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Page content
                Group {
                    switch selectedTab {
                    case .browse:
                        WordListView()
                    case .practice:
                        PracticeHubView()
                    case .stats:
                        StatsHubView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .environmentObject(store)
                // Extra bottom padding so content doesn't hide under tab bar
                .padding(.bottom, 80)

                // Tab bar (floats above content)
                CustomTabBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .environmentObject(store)
    }
}

// MARK: - Practice Hub
// Houses both FlashCard practice and Quiz mode.

private struct PracticeHubView: View {
    @EnvironmentObject var store: WordStore
    @State private var showQuiz = false

    var body: some View {
        ZStack {
            CardStackView()
                .environmentObject(store)

            // Quiz entry point: floating button on top-right of CardStack
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showQuiz = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.square")
                                .font(.system(size: 13, weight: .regular))
                            Text("Quiz")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(AppTheme.surface.opacity(0.90))
                                .overlay(Capsule().strokeBorder(AppTheme.border, lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 24)
                    .padding(.top, 16)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showQuiz) {
            QuizView().environmentObject(store)
        }
    }
}

// MARK: - Stats Hub
// Dashboard + Settings access.

private struct StatsHubView: View {
    @EnvironmentObject var store: WordStore
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            DashboardView()
                .environmentObject(store)

            // Settings gear
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 20)
            .padding(.top, 58)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(store)
        }
    }
}
