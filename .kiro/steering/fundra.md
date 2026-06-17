# Fundra Project Context

## App Overview
- Fundra is a privacy-first iOS savings tracker (iPhone-only, portrait-only)
- Built with SwiftUI, SwiftData, Swift Charts
- Fully offline — no network, no analytics, no accounts
- Target: iOS 18+, Xcode 27, launching September 2026

## Architecture
- Single file: ContentView.swift (all views)
- Models: Category and Balance (in Item.swift)
- Face ID/Touch ID lock on launch (FundraApp.swift)

## Design Decisions
- Forest green (#385C57) for dollar amounts
- Muted blue (#6E98C2) for branding
- MiniBarChartIcon used in all sheet headers (bar chart icon)
- MiniLineChartIcon used on Growth button (line chart icon in moneyGreen, same size/weight as Accounts header — Growth is an equal peer, not subordinate)
- Accounts sorted lowest-to-highest balance
- Account names in dark charcoal (Color(white: 0.35)) for hierarchy under bold header
- "Accounts" header toned down in dark mode (75% white instead of full white)
- Bar chart with tap-to-edit (hidden shortcut)
- Long-press context menu on account rows for Rename/Edit Balance/Delete
- Long-press date to delete month (triggers confirmation alert)
- Export/Save Chart positioned below the chart (not in account list)
- Quote section: minimal styling, no bubble/shadow, just text + refresh icon
- Easter egg: tap Fundra title → bars deflate and rebuild with spring animation; every 3rd tap triggers confetti
- One-time tooltip: "Tip: Long-press an account to rename or delete it." (auto-dismisses after 10s, uses @AppStorage)
- Record pre-fills amounts when editing an existing month; shows previous month's values as gray placeholder text for new months

## Validation Rules
- Record: all fields required, at least one > 0, zeros allowed
- Add Account: name + amount required, amount must be > 0
- Edit Balance: zero allowed
- 15-char limit on account names
- No duplicate names (case-insensitive) — checked in onboarding and Add Account
- Onboarding shows "Already added" warning for duplicate names in real-time
- No future dates (currently disabled for testing)
- Single decimal point, max 2 decimal places
- Input filter strips letters, special chars, multiple dots

## Interaction Patterns
- Tap account row → Edit Balance (or opens Record if no balance for that month)
- Long-press account row → context menu (Rename, Edit Balance, Delete)
- Long-press date → Delete Month confirmation
- Tap chart bar → Edit Balance (hidden shortcut)
- Delete last account warns "This is your last account. Deleting it will reset the app to setup."

## User Preferences
- Brian prefers practical solutions over theoretical ones
- Likes to discuss trade-offs before committing
- Appreciates when I proactively find issues
- Prefers short, direct answers unless exploring options
- Describe file locations simply (e.g., ".kiro → steering directory")
- Next priority: Goals feature (Pro, v2)

## Testing
- Unit tests exist in FundraTests for: filterAmountInput, abbreviatedAmount, formatFullAmount
- After modifying validation or formatting logic, remind Brian to run tests (⌘U in Xcode)

## TODO Before Release
- Re-add date restriction on Record DatePicker (currently removed for testing — change back to `in: ...Date()` before publishing)
