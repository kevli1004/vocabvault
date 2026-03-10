# VocabVault 📚

**A premium SAT vocabulary learning app built with SwiftUI and spaced repetition.**

## Overview

VocabVault is a stunning iOS app that makes learning SAT vocabulary feel like art. Built with pure SwiftUI (no external dependencies), it uses the SM-2 spaced repetition algorithm to ensure you learn efficiently and retain words long-term.

## Features

### 🃏 Flash Cards (Tinder-style)
- **Swipe RIGHT** → "I know this!" — advances mastery, positive SM-2 review
- **Swipe LEFT** → "Need more practice" — resets interval, negative SM-2 review  
- **Tap** → Flip card with beautiful 3D rotation to reveal definition, example, synonyms, etymology, and memory aid
- **Long press** → Bookmark / save for later
- Cards fly off in swipe direction with spring physics; next card scales up from below

### 🧠 Quiz Mode
- Multiple choice (4 options)
- 4 question types: word→definition, definition→word, fill-in-the-blank, synonym match
- Configurable length (5/10/15/20 questions)
- Focus mode: only quiz due words
- Animated feedback, confetti on perfect score
- Wrong answers review at the end

### 📊 Dashboard
- Time-aware greeting + daily streak counter
- Words mastered / total reviews / accuracy / daily goal
- Mastery breakdown bar (New → Learning → Reviewing → Mastered)
- Weekly progress chart
- Category breakdown with per-category mastery bars
- Rotating motivational quotes from famous linguists

### 📖 Word Browser
- Search by word or definition
- Filter by category (7 types) and mastery level
- Sort: A–Z, mastery, difficulty, due date
- Tap any word for full detail card (definition, example, synonyms, etymology, mnemonic, SRS stats)

### ⚙️ Settings
- Daily goal slider (5–50 words)
- Daily reminder toggle + time picker
- Full stats overview
- Reset progress (with confirmation)

## Word Data (~370 SAT words)

Every word includes:
- **Definition** — clear, SAT-appropriate
- **Example sentence** — natural, contextual
- **Synonyms** — 2-3 accurate alternatives
- **Etymology** — Latin, Greek, French, etc. origins
- **Mnemonic** — creative, memorable memory aids
- **Difficulty** — 1 (accessible) to 3 (advanced)
- **Category** — Character, Action, Description, Argument, Change, Quantity, Society

## Technical

- **Language:** Swift 5.9+
- **Framework:** SwiftUI (iOS 17+)
- **Algorithm:** SM-2 spaced repetition
- **Persistence:** UserDefaults (JSON-encoded progress)
- **Dependencies:** None — pure SwiftUI
- **Architecture:** MVVM with `@EnvironmentObject` store

## UI Design

Pastel gradient system with 7 palettes (purple, teal, coral, amber, mint, rose, lavender). Animated gradient blobs on the background shift subtly — the app feels alive. Glass morphism cards throughout. SF Symbols for all icons. Rounded system font for clean, modern typography.

## Project Structure

```
VocabVault/
├── VocabVault.xcodeproj/
└── VocabVault/
    ├── VocabVaultApp.swift
    ├── ContentView.swift
    ├── Models/
    │   ├── Word.swift              ← ~370 words + full data
    │   ├── WordStore.swift         ← ObservableObject store + persistence
    │   ├── SpacedRepetition.swift  ← SM-2 algorithm
    │   └── QuizEngine.swift        ← Quiz generation + session management
    ├── Views/
    │   ├── Home/DashboardView.swift
    │   ├── Cards/FlashCardView.swift   ← Tinder swipe mechanics
    │   ├── Cards/CardStackView.swift   ← Session engine + next-card animation
    │   ├── Cards/CardDetailView.swift  ← Full word detail
    │   ├── Quiz/QuizView.swift
    │   ├── Quiz/QuizResultsView.swift
    │   ├── Browse/WordListView.swift
    │   └── Settings/SettingsView.swift
    ├── Components/
    │   ├── GlassCard.swift         ← Reusable glass morphism cards
    │   ├── PastelGradients.swift   ← Animated gradient backgrounds
    │   ├── ConfettiView.swift      ← Physics-based confetti
    │   ├── AnimatedCounter.swift   ← Animated numbers, progress rings, bar charts
    │   └── CustomTabBar.swift      ← Glass effect tab bar
    └── Extensions/
        ├── Color+Pastels.swift     ← Full pastel palette
        └── View+Animations.swift  ← Shimmer, bounce, float modifiers
```

## Building

1. Open `VocabVault.xcodeproj` in Xcode 15+
2. Select an iPhone simulator (iOS 17+)
3. Build and run (`⌘R`)

No signing or provisioning required for simulator builds.
