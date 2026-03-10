import SwiftUI

// MARK: - Word List View

struct WordListView: View {
    @EnvironmentObject var store: WordStore
    @State private var searchText = ""
    @State private var selectedCategory: WordCategory? = nil
    @State private var selectedMastery: MasteryLevel? = nil
    @State private var sortOrder: SortOrder = .alphabetical
    @State private var showFilters = false
    @State private var selectedWord: Word? = nil

    enum SortOrder: String, CaseIterable {
        case alphabetical = "A–Z"
        case mastery      = "Mastery"
        case difficulty   = "Difficulty"
        case dueDate      = "Due Date"
    }

    private var filteredWords: [Word] {
        var result = store.words

        // Search
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.word.lowercased().contains(q) ||
                $0.definition.lowercased().contains(q) ||
                $0.synonyms.joined(separator: " ").lowercased().contains(q)
            }
        }

        // Category filter
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }

        // Mastery filter
        if let mastery = selectedMastery {
            result = result.filter { $0.masteryLevel == mastery }
        }

        // Sort
        switch sortOrder {
        case .alphabetical: result.sort { $0.word < $1.word }
        case .mastery:      result.sort { $0.masteryLevel.sortOrder < $1.masteryLevel.sortOrder }
        case .difficulty:   result.sort { $0.difficulty > $1.difficulty }
        case .dueDate:      result.sort { $0.nextReviewDate < $1.nextReviewDate }
        }

        return result
    }

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            VStack(spacing: 0) {
                // Header
                browseHeader

                // Filter pills
                if showFilters {
                    filterSection
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Word count
                HStack {
                    Text("\(filteredWords.count) words")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)

                // List
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredWords) { word in
                            WordRow(word: word)
                                .onTapGesture { selectedWord = word }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(item: $selectedWord) { word in
            CardDetailView(word: word)
                .environmentObject(store)
        }
    }

    // MARK: - Header

    private var browseHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Browse")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                // Sort menu
                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button(order.rawValue) { sortOrder = order }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                        Text(sortOrder.rawValue)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.1)))
                }

                Button {
                    withAnimation(.spring()) { showFilters.toggle() }
                } label: {
                    Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 22))
                        .foregroundColor(showFilters ? .gradPurple1 : .white.opacity(0.7))
                }
            }

            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.4))

                TextField("", text: $searchText, prompt: Text("Search words or definitions...")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
                )
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.white)

                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Filters

    private var filterSection: some View {
        VStack(spacing: 10) {
            // Category
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        label: "All Categories",
                        icon: "square.grid.2x2.fill",
                        isSelected: selectedCategory == nil
                    ) {
                        withAnimation { selectedCategory = nil }
                    }
                    ForEach(WordCategory.allCases, id: \.self) { cat in
                        FilterChip(
                            label: cat.rawValue,
                            icon: nil,
                            emoji: cat.emoji,
                            isSelected: selectedCategory == cat
                        ) {
                            withAnimation { selectedCategory = selectedCategory == cat ? nil : cat }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            // Mastery
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        label: "All Levels",
                        icon: "star.fill",
                        isSelected: selectedMastery == nil
                    ) {
                        withAnimation { selectedMastery = nil }
                    }
                    ForEach(MasteryLevel.allCases, id: \.self) { level in
                        FilterChip(
                            label: level.rawValue,
                            icon: nil,
                            color: Color.masteryColor(level),
                            isSelected: selectedMastery == level
                        ) {
                            withAnimation { selectedMastery = selectedMastery == level ? nil : level }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Word Row

private struct WordRow: View {
    let word: Word
    @State private var appear = false

    var body: some View {
        GlassCard(cornerRadius: 16, padding: 0, opacity: 0.1, shadowRadius: 8) {
            HStack(spacing: 14) {
                // Category color stripe
                let (c1, _) = Color.categoryGradient(word.category)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(c1)
                    .frame(width: 4)
                    .padding(.vertical, 12)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(word.word)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        MasteryBadge(level: word.masteryLevel)
                    }

                    Text(word.definition)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }
                .padding(.vertical, 14)
                .padding(.trailing, 16)

                if word.isFavorite {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.swipeFav)
                        .padding(.trailing, 14)
                }
            }
        }
        .scaleEffect(appear ? 1 : 0.97)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                appear = true
            }
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let label: String
    var icon: String?
    var emoji: String? = nil
    var color: Color? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let emoji {
                    Text(emoji).font(.system(size: 12))
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isSelected ? .white : (color ?? .white.opacity(0.5)))
                }
                if let c = color, !isSelected {
                    Circle().fill(c).frame(width: 8, height: 8)
                }
                Text(label)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected
                        ? (color ?? .gradPurple1).opacity(0.8)
                        : Color.white.opacity(0.08)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
