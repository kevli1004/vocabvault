import SwiftUI

// MARK: - Content View (Root)
// Four tabs: Browse, Practice, Quiz, Stats. No popups, no sheets, no toasts.

struct ContentView: View {
    @StateObject private var store = WordStore()
    @State private var selectedTab: AppTab = .practice

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .browse:   BrowseTab()
                case .practice: PracticeTab()
                case .quiz:     QuizTab()
                case .stats:    StatsTab()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: .bottom)
            .environmentObject(store)

            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .environmentObject(store)
    }
}

// MARK: - Browse Tab

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

// MARK: - Practice Tab (just the cards — nothing else)

private struct PracticeTab: View {
    @EnvironmentObject var store: WordStore

    var body: some View {
        CardStackView()
            .environmentObject(store)
    }
}

// MARK: - Quiz Tab

private struct QuizTab: View {
    @EnvironmentObject var store: WordStore

    var body: some View {
        QuizView()
            .environmentObject(store)
    }
}

// MARK: - Stats Tab (settings accessible via gear)

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
