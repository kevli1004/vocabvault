import SwiftUI

// MARK: - Word List View (Browse)
// Clean editorial list. Word + brief definition. Searchable. No decorations.

struct WordListView: View {
    @EnvironmentObject var store: WordStore
    @State private var searchText: String = ""
    @State private var selectedCategory: WordCategory? = nil
    @State private var showFavoritesOnly: Bool = false
    @State private var sortMode: SortMode = .alphabetical
    @State private var appear = false

    enum SortMode: String, CaseIterable {
        case alphabetical = "A–Z"
        case mastery      = "Mastery"
        case dueFirst     = "Due First"
        case recent       = "Recent"
    }

    // MARK: - Filtered / Sorted Words

    private var filteredWords: [Word] {
        var words = store.words

        // Search
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            words = words.filter {
                $0.word.lowercased().contains(q) ||
                $0.definition.lowercased().contains(q)
            }
        }

        // Favorites filter
        if showFavoritesOnly {
            words = words.filter { $0.isFavorite }
        }

        // Category filter
        if let cat = selectedCategory {
            words = words.filter { $0.category == cat }
        }

        // Sort
        switch sortMode {
        case .alphabetical: words.sort { $0.word < $1.word }
        case .mastery:      words.sort { $0.masteryLevel.sortOrder < $1.masteryLevel.sortOrder }
        case .dueFirst:     words.sort { $0.isDueForReview && !$1.isDueForReview }
        case .recent:       words.sort { $0.timesCorrect + $0.timesIncorrect > $1.timesCorrect + $1.timesIncorrect }
        }

        return words
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                listHeader
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 16)

                // Search bar
                searchBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Category filter chips
                categoryFilter
                    .padding(.bottom, 8)

                MinimalDivider()

                // Sort row
                sortRow
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)

                MinimalDivider()

                // Word list
                wordList
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) { appear = true }
        }
    }

    // MARK: - Header

    private var listHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Browse")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(AppTheme.text)

            Spacer()

            Text("\(filteredWords.count)")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(AppTheme.textTertiary)
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 8)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundColor(AppTheme.textTertiary)

            TextField("Search words...", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(AppTheme.text)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.textTertiary)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(AppTheme.border, lineWidth: 1)
                )
        )
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                FilterChip(label: "All", isActive: selectedCategory == nil && !showFavoritesOnly) {
                    selectedCategory = nil
                    showFavoritesOnly = false
                }

                // Favorites chip
                FilterChip(label: "♡ Favorites", isActive: showFavoritesOnly) {
                    showFavoritesOnly.toggle()
                    if showFavoritesOnly { selectedCategory = nil }
                }

                ForEach(WordCategory.allCases, id: \.self) { cat in
                    FilterChip(
                        label: "\(cat.emoji) \(cat.rawValue)",
                        isActive: selectedCategory == cat
                    ) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                        showFavoritesOnly = false
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Sort Row

    private var sortRow: some View {
        HStack {
            Text("Sort:")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(AppTheme.textTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SortMode.allCases, id: \.self) { mode in
                        Button {
                            sortMode = mode
                        } label: {
                            Text(mode.rawValue)
                                .font(.system(size: 12, weight: sortMode == mode ? .semibold : .regular))
                                .foregroundColor(sortMode == mode ? AppTheme.text : AppTheme.textTertiary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(sortMode == mode ? AppTheme.surface : Color.clear)
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(sortMode == mode ? AppTheme.border : Color.clear, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Word List

    private var wordList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0, pinnedViews: []) {
                if filteredWords.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(filteredWords.enumerated()), id: \.element.id) { i, word in
                        NavigationLink(destination: CardDetailView(word: word)) {
                            WordRow(word: word)
                        }
                        .buttonStyle(.plain)

                        if i < filteredWords.count - 1 {
                            MinimalDivider()
                                .padding(.leading, 24)
                        }
                    }
                }
            }
            .padding(.bottom, 80)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No words found")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppTheme.text)
                .padding(.top, 60)
            Text("Try a different search or filter.")
                .font(.system(size: 15))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Word Row

private struct WordRow: View {
    let word: Word

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Pastel color tab
            RoundedRectangle(cornerRadius: 3)
                .fill(CardPalette.color(for: word.category))
                .frame(width: 3, height: 44)
                .padding(.leading, 24)
                .padding(.vertical, 16)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(word.word)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.text)

                    if word.isDueForReview {
                        Circle()
                            .fill(CardPalette.peach)
                            .frame(width: 5, height: 5)
                    }

                    Spacer()

                    MasteryDot(level: word.masteryLevel)
                }

                Text(word.definition)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 16)
            .padding(.trailing, 24)
        }
        .background(AppTheme.background)
        .contentShape(Rectangle())
    }
}

// MARK: - Mastery Dot (tiny indicator)

private struct MasteryDot: View {
    let level: MasteryLevel

    private var color: Color {
        switch level {
        case .new:       return AppTheme.border
        case .learning:  return CardPalette.skyBlue
        case .reviewing: return CardPalette.peach
        case .mastered:  return CardPalette.mint
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? AppTheme.text : AppTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isActive ? AppTheme.surface : Color.clear)
                        .overlay(
                            Capsule()
                                .strokeBorder(isActive ? AppTheme.border : AppTheme.separator, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isActive)
    }
}
