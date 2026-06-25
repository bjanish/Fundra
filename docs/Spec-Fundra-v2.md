# Fundra v2.0 — Spec Sheet

## Summary
Major update introducing Pro tier with Goals, improved charts, locale-aware currency, and HYSA rate insights. One-time IAP (~$3.99) unlocks Pro features.

---

## Phase 1: Foundation (do first)

### 1. Locale-Aware Currency Formatting
- **What:** Replace all hardcoded `$` with device locale currency (USD, EUR, GBP, JPY, etc.)
- **How:** Single shared `NumberFormatter` with `.currencyStyle` and `Locale.current`
- **Touches:** formatFullAmount, abbreviatedAmount, chart annotations, input fields, Growth view
- **Input handling:** Support `,` as decimal separator for European locales
- **Testing:** Verify in Simulator with US, France, Japan, UK regions
- **Effort:** ~30 min coding, ~30 min testing

---

## Phase 2: Pro Features

### 2. Goals
- **What:** Set savings goals per account or overall, track progress toward them
- **UX:** Goal amount + optional target date; progress bar or ring on main screen
- **Data model:** New `Goal` entity (target amount, target date, linked category or "total")
- **Displays:** Progress percentage, amount remaining, estimated completion date
- **Pro-only:** Free users see the Goals button but get a Pro unlock prompt

### 3. Cumulative Monthly Bar Chart
- **What:** Each bar = total savings across ALL accounts for that month
- **Purpose:** Shows overall savings trajectory at a glance (forest vs. trees)
- **Placement:** Accessible from main screen (new tab or toggle on existing chart)
- **Pro-only:** Yes

### 4. Horizontal Bar Chart
- **What:** Alternative chart layout that scales to many accounts
- **Purpose:** Enables lifting the 6-account limit for Pro users
- **Behavior:** Auto-switches to horizontal at 7+ accounts, or user toggle
- **Pro-only:** Unlocking >6 accounts is Pro; the chart adapts

### 5. HYSA Rate Feature
- **What:** Show current high-yield savings rates + projected earnings
- **Display:** "Your $19,120 could earn ~$860/year at 4.5% APY"
- **API:** TBD — research free rate APIs or use Fed funds rate as proxy
- **Monetization:** Personal referral link from day one (earns $50–$200 per funded account)
- **Pro-only:** TBD — could be free to drive referral revenue, or Pro-only for exclusivity

---

## Phase 3: Polish

### 6. Design Polish Pass
- Spacing and alignment consistency audit
- Typography hierarchy refinement (weight/size relationships)
- Subtle transitions and micro-animations
- Dark mode intentionality check
- Empty states that feel designed
- Chart styling consistency across all chart types

---

## Monetization Strategy

| Revenue Stream | When | Scale Needed |
|---|---|---|
| Pro IAP ($3.99 one-time) | v2.0 launch | Any — works from day one |
| HYSA referral link | When HYSA feature ships | Any — even 1 sign-up earns |
| Direct bank sponsorship | Future | Thousands of users |

---

## Technical Decisions

- **StoreKit 2** for IAP (modern API, iOS 15+, simpler than StoreKit 1)
- **No subscription** — one-time purchase matches app philosophy
- **Offline-first stays** — HYSA rates cached, refreshed when online
- **Privacy policy update** — HYSA feature makes one network call; disclose in privacy policy
- **New data model:** Goal entity in SwiftData

---

## Build Order

1. Currency formatting (foundation — everything after depends on it)
2. Goals (headline Pro feature)
3. Cumulative chart (complements Goals)
4. Horizontal chart + lift account limit (Pro perk)
5. HYSA rates (API research needed, can parallel other work)
6. Design polish (final pass before submission)
7. StoreKit integration + Pro unlock gate (after features are built)

---

## Release Plan

- Branch: `v2.0` from main after v1.1.1 ships
- Changelog: `docs/Changelog-2.0.md`
- App Store version: 2.0
- Manual release (set in App Store Connect)
- New screenshots needed for Pro features
- Update App Store description + keywords for Goals/HYSA
