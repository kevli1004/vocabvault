import SwiftUI

// MARK: - Pastel Color Palette

extension Color {

    // MARK: - Core Pastel Gradients

    static let gradPurple1  = Color(red: 0.71, green: 0.60, blue: 0.94)
    static let gradPurple2  = Color(red: 0.55, green: 0.40, blue: 0.86)

    static let gradTeal1    = Color(red: 0.45, green: 0.82, blue: 0.84)
    static let gradTeal2    = Color(red: 0.28, green: 0.65, blue: 0.77)

    static let gradCoral1   = Color(red: 1.00, green: 0.68, blue: 0.64)
    static let gradCoral2   = Color(red: 0.96, green: 0.50, blue: 0.48)

    static let gradAmber1   = Color(red: 1.00, green: 0.84, blue: 0.55)
    static let gradAmber2   = Color(red: 0.98, green: 0.68, blue: 0.32)

    static let gradMint1    = Color(red: 0.60, green: 0.94, blue: 0.80)
    static let gradMint2    = Color(red: 0.38, green: 0.80, blue: 0.66)

    static let gradRose1    = Color(red: 1.00, green: 0.72, blue: 0.86)
    static let gradRose2    = Color(red: 0.94, green: 0.52, blue: 0.74)

    static let gradLav1     = Color(red: 0.82, green: 0.74, blue: 0.98)
    static let gradLav2     = Color(red: 0.66, green: 0.54, blue: 0.92)

    // MARK: - Background Gradients

    static let bgDark1      = Color(red: 0.08, green: 0.07, blue: 0.14)
    static let bgDark2      = Color(red: 0.12, green: 0.10, blue: 0.20)

    // MARK: - Mastery Level Colors

    static let masteryNew       = Color(red: 0.65, green: 0.65, blue: 0.72)
    static let masteryLearning  = Color(red: 0.45, green: 0.70, blue: 0.98)
    static let masteryReviewing = Color(red: 0.98, green: 0.72, blue: 0.35)
    static let masteryMastered  = Color(red: 0.38, green: 0.82, blue: 0.62)

    // MARK: - Swipe Indicator Colors

    static let swipeRight = Color(red: 0.27, green: 0.88, blue: 0.55)
    static let swipeLeft  = Color(red: 0.96, green: 0.38, blue: 0.46)
    static let swipeFav   = Color(red: 0.98, green: 0.80, blue: 0.30)

    // MARK: - Category Color Lookup

    static func gradientColors(for palette: GradientPalette) -> (Color, Color) {
        switch palette {
        case .purple:   return (.gradPurple1, .gradPurple2)
        case .teal:     return (.gradTeal1,   .gradTeal2)
        case .coral:    return (.gradCoral1,  .gradCoral2)
        case .amber:    return (.gradAmber1,  .gradAmber2)
        case .mint:     return (.gradMint1,   .gradMint2)
        case .rose:     return (.gradRose1,   .gradRose2)
        case .lavender: return (.gradLav1,    .gradLav2)
        }
    }

    static func categoryGradient(_ category: WordCategory) -> (Color, Color) {
        gradientColors(for: category.color)
    }

    // MARK: - Mastery Color

    static func masteryColor(_ level: MasteryLevel) -> Color {
        switch level {
        case .new:       return .masteryNew
        case .learning:  return .masteryLearning
        case .reviewing: return .masteryReviewing
        case .mastered:  return .masteryMastered
        }
    }
}

// MARK: - LinearGradient Helpers

extension LinearGradient {

    static func pastelGradient(for palette: GradientPalette, angle: Angle = .init(degrees: 135)) -> LinearGradient {
        let (c1, c2) = Color.gradientColors(for: palette)
        return LinearGradient(
            colors: [c1, c2],
            startPoint: UnitPoint(x: 0, y: 0),
            endPoint: UnitPoint(x: cos(angle.radians), y: sin(angle.radians))
        )
    }

    static func categoryGradient(_ category: WordCategory) -> LinearGradient {
        pastelGradient(for: category.color)
    }

    static var appBackground: LinearGradient {
        LinearGradient(
            colors: [Color.bgDark1, Color.bgDark2],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
