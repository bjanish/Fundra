# Card Draw App — Concept Doc

## Overview
A "drawing straws" app using playing cards. Each person opens the app, draws a random card — highest card wins. Dead simple, no accounts, no networking, fully offline.

## Core Experience
- One screen
- Card displayed face-down on launch
- Tap to flip (3D flip animation)
- Random card from a 52-card deck (independent draws per device)
- "Draw Again" button to reset
- Ties? Redraw in person

## Design
- Single view app
- Card rendered in SwiftUI (no image assets needed)
  - Face: RoundedRectangle, rank in corners, suit pips in standard layout
  - Back: RoundedRectangle with pattern/design (solid color + border motif)
- Flip animation: `.rotation3DEffect` on Y axis
- Minimal UI — card dominates the screen

## Tech
- SwiftUI, no external dependencies
- Pure Apple frameworks (same approach as Fundra)
- iOS 18+ target
- No networking, no data persistence needed
- Random card: `Int.random(in: 0..<52)` mapped to rank + suit

## Scope
- v1.0: Single draw, flip animation, draw again
- Future ideas:
  - Haptic on flip
  - Sound effect (card snap)
  - History of draws in current session
  - "War mode" — two cards, auto-compare
  - Share result (screenshot or activity sheet)
  - Custom card back designs

## Monetization
- Free (too simple to charge for)
- Could be a portfolio piece / fun side project
- Or: ad-supported if you want passive income from a simple utility

## Monetization notes:
- Core draw mechanic MUST stay free (virality depends on everyone being able to play instantly)
- Monetize with: custom card backs/themes, extra game modes, or remove ads
- Never lock out a player mid-party — kills the group dynamic
- Built-in virality: everyone in the group must download to participate = organic growth loop
- See `docs/CardApp-Idea.md` for full concept

## Notes
- Independent random draws (no shared deck across devices)
- Ties = redraw in person
- Same philosophy as Fundra: privacy-first, offline, no accounts, just works
- Separate Xcode project + repo from Fundra
- Brian is EXCITED about this — don't let it get lost. Bring it up next session.
