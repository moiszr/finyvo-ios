# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build (Debug)
xcodebuild -scheme Finyvo -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Build (Release)
xcodebuild -scheme Finyvo -configuration Release build

# Run tests
xcodebuild -scheme Finyvo -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

No external package managers (SPM, CocoaPods, Carthage). All dependencies are Apple frameworks.

## Architecture

**iOS app** built with **Swift 6**, **SwiftUI**, and **SwiftData**. Targets iOS 16+ with iOS 26+ liquid glass UI support.

### Feature-Driven MVVM

Each feature lives in `Finyvo/Features/<Feature>/` with this structure:
- `Models/` — SwiftData `@Model` entities
- `ViewModels/` — `@Observable` view models for business logic
- `Views/` — SwiftUI views; use `@Query` for reactive data, `@State` VMs for UI state
- `Views/Components/` — Feature-specific reusable views

Current features: **Categories**, **Transactions**, **Wallets**, **Tags**, **Onboarding**

### Key Directories

- `App/` — Entry point (`FinyvoApp.swift`) and global `AppState` (onboarding, auth, currency)
- `Navigation/` — `AppRouter` with tab-based navigation and modal overlays
- `Config/` — `AppConfig` (feature flags, limits) and `Constants` (animations, haptics, timing, storage keys)
- `Domain/Currency/` — Currency model with 95+ currencies and formatting
- `Core/` — Shared extensions (`Double+Formatting`, `Date+Formatting`, etc.) and utilities
- `DesignSystem/` — UI tokens (`FColors`, `FSpacing`, `FCardColor`) and components (`FButton`, `FInput`)

### Data Layer Patterns

All entities use SwiftData `@Model` with **type-safe computed accessors** over raw string fields:
```swift
// Raw field stored in SwiftData
var typeRaw: String = TransactionType.expense.rawValue
// Type-safe accessor
var type: TransactionType {
    get { TransactionType(rawValue: typeRaw) ?? .expense }
    set { typeRaw = newValue.rawValue }
}
```

Relationships: one-to-many (Category → children, cascade delete), many-to-many (Transaction ↔ Tags). Soft delete via `isArchived` flag. No manual persistence calls — SwiftData handles CRUD through `ModelContext`.

New `@Model` types must be registered in the schema array in `FinyvoApp.swift`.

### SwiftData Schema

All models registered in `FinyvoApp.sharedModelContainer`: `Category`, `Tag`, `Wallet`, `Transaction`.

## Conventions

- **Language**: Code comments and UI strings are in **Spanish**. Variable/type names are in English.
- **Design system first**: Use `FColors`, `FSpacing`, `FCardColor`, `FCategoryIcon` tokens — not raw colors or magic numbers.
- **Animations**: Use presets from `Constants.Animation` (e.g., `.defaultSpring`, `.quickSpring`).
- **Haptics**: Use `Constants.Haptic` methods (`.light()`, `.success()`, `.error()`).
- **Feature flags and limits**: Defined in `AppConfig`. Check flags before enabling new modules.
- **Default locale**: `es_US` (set in `AppConfig.Defaults.localeIdentifier`).
