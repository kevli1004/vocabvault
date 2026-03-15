import SwiftUI

// MARK: - Tab Identifier (4 tabs)

enum AppTab: Int, CaseIterable {
    case browse   = 0
    case practice = 1
    case quiz     = 2
    case stats    = 3
}

// MARK: - Custom Tab Bar
// Ultra-minimal: four small dots. No labels. Nearly invisible.

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 28) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Circle()
                        .fill(selectedTab == tab ? AppTheme.text : AppTheme.border)
                        .frame(width: selectedTab == tab ? 8 : 6, height: selectedTab == tab ? 8 : 6)
                        .animation(.easeOut(duration: 0.15), value: selectedTab)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 14)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(
            AppTheme.background.opacity(0.95)
        )
    }
}
