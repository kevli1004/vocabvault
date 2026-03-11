import SwiftUI

// MARK: - Tab Identifier

enum AppTab: Int, CaseIterable {
    case browse   = 0
    case practice = 1
    case stats    = 2
    case settings = 3
}

// MARK: - Custom Tab Bar
// Clean, cream background with thin top border.
// Three primary items: Browse (grid), Practice (pill CTA), Stats (bar chart).
// Settings is accessible but doesn't live in the main bar.

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Browse
            TabBarItem(
                icon: "square.grid.2x2",
                label: "Browse",
                isSelected: selectedTab == .browse
            ) {
                selectedTab = .browse
            }

            Spacer()

            // Practice (center pill)
            PracticeButton(isSelected: selectedTab == .practice) {
                selectedTab = .practice
            }

            Spacer()

            // Stats
            TabBarItem(
                icon: "chart.bar",
                label: "Stats",
                isSelected: selectedTab == .stats
            ) {
                selectedTab = .stats
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            ZStack(alignment: .top) {
                AppTheme.background

                // Top separator line
                Rectangle()
                    .fill(AppTheme.border)
                    .frame(height: 1)
            }
        )
    }
}

// MARK: - Tab Bar Item

private struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: isSelected ? icon + ".fill" : icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(isSelected ? AppTheme.text : AppTheme.textTertiary)

                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppTheme.text : AppTheme.textTertiary)
            }
            .frame(width: 60)
            .animation(.easeOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Practice Button (center pill CTA)

private struct PracticeButton: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? AppTheme.text : AppTheme.surface)
                        .frame(width: 56, height: 38)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(AppTheme.border, lineWidth: isSelected ? 0 : 1)
                        )

                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                }

                Text("Practice")
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppTheme.text : AppTheme.textTertiary)
            }
            .animation(.easeOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Main Content Switcher
// Wraps the tab bar with the selected view.

struct MainContentView: View {
    @StateObject private var store = WordStore()
    @State private var selectedTab: AppTab = .practice

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content area
            Group {
                switch selectedTab {
                case .browse:   WordListView()
                case .practice: CardStackView()
                case .stats:    DashboardView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(store)

            // Tab bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
