import SwiftUI

// MARK: - Content View (Root)

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            TabContent(selectedTab: $selectedTab)
                .ignoresSafeArea(edges: .bottom)

            // Custom tab bar
            VStack(spacing: 0) {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
                    .padding(.bottom, 8)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Tab Content

private struct TabContent: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        ZStack {
            DashboardView(selectedTab: $selectedTab)
                .opacity(selectedTab == .home ? 1 : 0)

            CardStackView()
                .opacity(selectedTab == .cards ? 1 : 0)

            QuizView()
                .opacity(selectedTab == .quiz ? 1 : 0)

            WordListView()
                .opacity(selectedTab == .browse ? 1 : 0)

            SettingsView()
                .opacity(selectedTab == .settings ? 1 : 0)
        }
    }
}
