import SwiftUI

// MARK: - App Theme

struct AppTheme {
    // Backgrounds
    static let background    = Color(red: 0.961, green: 0.941, blue: 0.910) // #F5F0E8 warm cream
    static let surface       = Color(red: 0.980, green: 0.976, blue: 0.969) // #FAFAF7 off-white
    static let surfaceWarm   = Color(red: 0.945, green: 0.929, blue: 0.906) // slightly darker cream

    // Text
    static let text          = Color(red: 0.102, green: 0.102, blue: 0.102) // #1A1A1A near black
    static let textSecondary = Color(red: 0.541, green: 0.541, blue: 0.541) // #8A8A8A medium gray
    static let textTertiary  = Color(red: 0.729, green: 0.729, blue: 0.729) // #BABABA light gray

    // Borders & Separators
    static let border        = Color(red: 0.878, green: 0.859, blue: 0.831) // #E0DBD4 subtle
    static let separator     = Color(red: 0.925, green: 0.914, blue: 0.898) // #ECEAE5 very subtle

    // Accent (black)
    static let accent        = Color(red: 0.102, green: 0.102, blue: 0.102)

    // Functional colors (muted, editorial)
    static let success       = Color(red: 0.290, green: 0.600, blue: 0.420) // muted green
    static let error         = Color(red: 0.780, green: 0.290, blue: 0.290) // muted red
    static let warning       = Color(red: 0.820, green: 0.600, blue: 0.200) // muted amber
}

// MARK: - Card Pastel Colors (for FlashCard full-bleed backgrounds)

struct CardPalette {
    // Solid flat pastels — one per card category
    static let lavender   = Color(red: 0.816, green: 0.761, blue: 0.898) // character
    static let skyBlue    = Color(red: 0.718, green: 0.843, blue: 0.918) // action
    static let mint       = Color(red: 0.718, green: 0.851, blue: 0.780) // description
    static let sage       = Color(red: 0.753, green: 0.816, blue: 0.753) // argument
    static let peach      = Color(red: 0.941, green: 0.816, blue: 0.718) // change
    static let dustyRose  = Color(red: 0.910, green: 0.776, blue: 0.776) // quantity
    static let butter     = Color(red: 0.953, green: 0.882, blue: 0.718) // society

    static func color(for category: WordCategory) -> Color {
        switch category {
        case .character:   return lavender
        case .action:      return skyBlue
        case .description: return mint
        case .argument:    return sage
        case .change:      return peach
        case .quantity:    return dustyRose
        case .society:     return butter
        }
    }

    // Returns a rotating color from a global index (for variety even within same category)
    static let rotatingPalette: [Color] = [
        lavender, skyBlue, mint, peach, dustyRose, sage, butter
    ]

    static func rotating(index: Int) -> Color {
        rotatingPalette[index % rotatingPalette.count]
    }

    // Text color that works on any card pastel (always dark — all pastels are light)
    static let cardText = Color(red: 0.102, green: 0.102, blue: 0.102)
    static let cardTextSecondary = Color(red: 0.280, green: 0.280, blue: 0.280)
    static let cardTextTertiary  = Color(red: 0.420, green: 0.420, blue: 0.420)
}

// MARK: - Legacy Color Extensions (kept for compatibility where still used)

extension Color {
    // Swipe action colors (now muted)
    static let swipeRight = Color(red: 0.290, green: 0.600, blue: 0.420)
    static let swipeLeft  = Color(red: 0.780, green: 0.290, blue: 0.290)
    static let swipeFav   = Color(red: 0.820, green: 0.600, blue: 0.200)

    // Mastery level colors (muted editorial palette)
    static let masteryNew       = AppTheme.textTertiary
    static let masteryLearning  = Color(red: 0.718, green: 0.843, blue: 0.918)
    static let masteryReviewing = Color(red: 0.941, green: 0.816, blue: 0.718)
    static let masteryMastered  = Color(red: 0.718, green: 0.851, blue: 0.780)

    // Named palette shims (for files that still reference old names)
    static let gradPurple1  = CardPalette.lavender
    static let gradPurple2  = CardPalette.lavender
    static let gradTeal1    = CardPalette.skyBlue
    static let gradTeal2    = CardPalette.skyBlue
    static let gradCoral1   = CardPalette.peach
    static let gradCoral2   = CardPalette.peach
    static let gradAmber1   = CardPalette.butter
    static let gradAmber2   = CardPalette.butter
    static let gradMint1    = CardPalette.mint
    static let gradMint2    = CardPalette.mint
    static let gradRose1    = CardPalette.dustyRose
    static let gradRose2    = CardPalette.dustyRose
    static let gradLav1     = CardPalette.lavender
    static let gradLav2     = CardPalette.lavender

    // Category solid color (single, no gradient)
    static func categoryColor(_ category: WordCategory) -> Color {
        CardPalette.color(for: category)
    }

    // Legacy: categoryGradient returns matching pair (both same color — no gradient)
    static func categoryGradient(_ category: WordCategory) -> (Color, Color) {
        let c = CardPalette.color(for: category)
        return (c, c)
    }
}

// MARK: - LinearGradient shims (legacy callers expect these)

extension LinearGradient {
    static func pastelGradient(for palette: GradientPalette, angle: Angle = .init(degrees: 135)) -> LinearGradient {
        // Flat — same color, no visible gradient
        let c: Color
        switch palette {
        case .purple:   c = CardPalette.lavender
        case .teal:     c = CardPalette.skyBlue
        case .coral:    c = CardPalette.peach
        case .amber:    c = CardPalette.butter
        case .mint:     c = CardPalette.mint
        case .rose:     c = CardPalette.dustyRose
        case .lavender: c = CardPalette.lavender
        }
        return LinearGradient(colors: [c, c], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func categoryGradient(_ category: WordCategory) -> LinearGradient {
        let c = CardPalette.color(for: category)
        return LinearGradient(colors: [c, c], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
