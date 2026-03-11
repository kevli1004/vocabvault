import SwiftUI

// MARK: - Content View (Root)
// Tab-based navigation. NavigationStack lives only inside Browse, where push is needed.

struct ContentView: View {
    @StateObject private var store = WordStore()
    @State private var selectedTab: AppTab = .practice

    var body: some View {
        ZStack(alignment: .bottom) {
            // Page content (ignores bottom so tab bar can overlay)
            Group {
                switch selectedTab {
                case .browse:   BrowseTab()
                case .practice: PracticeTab()
                case .stats:    StatsTab()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: .bottom)
            .environmentObject(store)

            // Tab bar floats at bottom
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .environmentObject(store)
    }
}

// MARK: - Browse Tab (owns the NavigationStack for push nav)

private struct BrowseTab: View {
    @EnvironmentObject var store: WordStore

    var body: some View {
        NavigationStack {
            WordListView()
                .environmentObject(store)
                .navigationBarHidden(true)
        }
    }
}

// MARK: - Practice Tab
// Flash cards (full-bleed pastel). Quiz accessible via floating button.

private struct PracticeTab: View {
    @EnvironmentObject var store: WordStore
    @State private var showQuiz = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            CardStackView()
                .environmentObject(store)

            // Quiz shortcut pill
            Button {
                showQuiz = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.square")
                        .font(.system(size: 12, weight: .regular))
                    Text("Quiz")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(AppTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(AppTheme.surface.opacity(0.88))
                        .overlay(Capsule().strokeBorder(AppTheme.border, lineWidth: 1))
                )
            }
            .buttonStyle(.plain)
            .padding(.trailing, 24)
            .padding(.top, 60)
        }
        .sheet(isPresented: $showQuiz) {
            QuizView().environmentObject(store)
        }
    }
}

// MARK: - Stats Tab
// Dashboard with settings gear in the corner.

private struct StatsTab: View {
    @EnvironmentObject var store: WordStore
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            DashboardView()
                .environmentObject(store)

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppTheme.textTertiary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 24)
            .padding(.top, 58)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(store)
        }
    }
}
