import SwiftUI

// MARK: - Tab Item

enum AppTab: Int, CaseIterable {
    case home    = 0
    case cards   = 1
    case quiz    = 2
    case browse  = 3
    case settings = 4

    var title: String {
        switch self {
        case .home:     return "Home"
        case .cards:    return "Cards"
        case .quiz:     return "Quiz"
        case .browse:   return "Browse"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home:     return "house.fill"
        case .cards:    return "rectangle.stack.fill"
        case .quiz:     return "checkmark.circle.fill"
        case .browse:   return "books.vertical.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var activeGradient: GradientPalette {
        switch self {
        case .home:     return .purple
        case .cards:    return .teal
        case .quiz:     return .coral
        case .browse:   return .amber
        case .settings: return .lavender
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: animation
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 8)
        .padding(.horizontal, 20)
    }
}

// MARK: - Tab Bar Button

private struct TabBarButton: View {
    let tab: AppTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    @State private var bouncing = false

    var body: some View {
        Button(action: {
            bouncing = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                bouncing = false
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient.pastelGradient(for: tab.activeGradient)
                            )
                            .frame(width: 48, height: 32)
                            .matchedGeometryEffect(id: "tab_bg", in: namespace)
                            .shadow(
                                color: Color.gradientColors(for: tab.activeGradient).0.opacity(0.5),
                                radius: 8, x: 0, y: 4
                            )
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.4))
                        .frame(width: 48, height: 32)
                        .scaleEffect(bouncing ? 1.25 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: bouncing)
                }

                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .regular, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }
}
