# Card Draw App — Spec Sheet

## Summary
A dead-simple "drawing straws" party app. Everyone draws a random card — highest wins. Built-in virality: all players must download to participate.

---

## Core Product

### The Experience
1. Open app
2. See card face-down
3. Tap to flip (3D animation)
4. See your card
5. Compare with friends in person
6. Tap "Draw Again" to reset

### One Sentence Pitch
"Everyone draws a card. Lowest card drinks."

---

## v1.0 Scope

### Screen: Single View
- Full-screen card (dominates the view)
- Card back design on launch
- Tap anywhere to flip
- "Draw Again" button below card (appears after flip)
- Subtle branding at top or bottom

### Card Rendering (SwiftUI, no assets)
- **Face:** White RoundedRectangle, rank in corners (A, 2–10, J, Q, K), suit symbols (♠ ♥ ♦ ♣) in standard pip layout, red for hearts/diamonds
- **Back:** Colored RoundedRectangle with geometric pattern or crosshatch design
- **Flip animation:** `.rotation3DEffect` on Y axis, 0.4s, card back → card face

### Logic
- 52-card deck (no jokers)
- Independent random draw per device (no shared state)
- `Int.random(in: 0..<52)` → map to rank + suit
- Ties resolved in person (redraw)

### Tech Stack
- SwiftUI
- No external dependencies
- No networking (v1)
- No data persistence
- iOS 18+ target
- iPhone only, portrait only

---

## v1.1+ Ideas (Future)

### Enhancements
- Haptic feedback on flip (medium impact)
- Card snap sound effect
- Session history (cards drawn this round)
- Shake to draw (accelerometer trigger)

### Game Modes (Pro potential)
- **War:** Two cards auto-dealt, higher wins
- **High/Low:** Guess if next card is higher or lower
- **Elimination:** Multi-round, lowest card is out each round
- **Custom rules:** User sets what each card means

### Customization (Pro potential)
- Custom card back designs/colors
- Card face themes (minimal, classic, neon)
- Dark mode

### Social
- Share result card as image (activity sheet)
- "Challenge a friend" — generates App Store link with pre-filled message

---

## Monetization

### Strategy: Free core, paid extras
| Revenue Stream | What | Price |
|---|---|---|
| Remove ads | Banner ad during idle, removed with purchase | $1.99 |
| Card themes | Custom backs + face designs | $0.99–$2.99 |
| Game modes | War, High/Low, Elimination | $2.99 bundle |

### Rules
- Core draw mechanic is ALWAYS free — never lock out a player
- Virality depends on zero friction at download
- Ads: non-intrusive (no interstitials during gameplay, banner only on idle/results)

---

## Virality Mechanics

- **Multiplayer requires download:** Every player needs the app → organic growth
- **In-person social:** App is shown in groups → "what's that?" → instant download
- **Shareable moments:** Funny draws, close calls → screenshot/share
- **One-sentence explainable:** No tutorial needed, anyone gets it instantly
- **Party context:** Drinking games, decision-making, settling bets

---

## Design Principles

- Instant — no onboarding, no account, no loading
- Bold — card should be the star, everything else recedes
- Fun — animations, haptics, satisfying interactions
- Inclusive — anyone can play regardless of language (cards are universal)

---

## Build Plan

1. Card model (rank + suit enum, random draw logic)
2. Card face view (SwiftUI shapes + text)
3. Card back view (pattern design)
4. Flip animation
5. Main screen layout (card + draw button)
6. Haptic feedback
7. Polish + App Store listing
8. Ship v1.0

**Estimated time:** 1–2 sessions

---

## App Store Strategy

- **Name:** TBD (brainstorm: DrawUp, CardPull, FlipDraw, TopCard, HighDraw)
- **Category:** Entertainment or Games → Card
- **Rating:** 4+ (no drinking references in listing) or 17+ (if marketed as party/drinking)
- **Keywords:** card game, party game, drinking game, draw card, random card, decision maker
- **Screenshots:** Show the flip animation sequence, group context
- **Price:** Free

---

## Separate Project
- New Xcode project (not in Fundra repo)
- New GitHub repo
- New App Store listing
- Same Apple Developer account
