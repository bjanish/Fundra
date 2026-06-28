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

## Marketing Strategy (College Students)

### Viral Mechanics
- "You need 3+ players to start" — forces the downloader to recruit friends
- Share a game code / QR that deep-links friends directly into a room
- Post-game shareable results card (like Wordle's grid) for stories/group chats
- "Challenge [friend's name]" button that sends an iMessage with app link

### Campus-Specific Tactics
- Target one dorm or friend group hard — if 5 people have it, the rest download out of FOMO
- Offer student orgs a custom card back skin if they get 50 downloads from their campus
- Position as "the pregame app" or "the game that replaces Cards Against Humanity"
- Launch week: make it free, then go paid/IAP once traction builds

### Custom Card Back Skins (Key Idea)
- Each student org gets their own branded card back design at a download threshold
- Digital merch that costs nothing to produce
- Acts as both reward and in-game flex
- Could be the monetization hook too — sell premium skins to individuals
- **User-uploaded card backs:** allow users to pick an image from their photo library as a custom card back (crop to card aspect ratio, stored locally). Personal photos, team logos, inside jokes — makes the game theirs.

### Content & Social
- TikTok clips of friend groups playing and reacting — reactions sell party games
- "This app ended a friendship" style organic-feeling content
- Reddit posts in college subreddits (r/college, specific school subs)

### Core Insight
- Party games spread through social proof, not features
- One viral TikTok of people laughing while playing > any feature list
- App must be dead simple to get into (under 10 seconds from download to playing)

## Notes
- Independent random draws (no shared deck across devices)
- Ties = redraw in person
- Same philosophy as Fundra: privacy-first, offline, no accounts, just works
- Separate Xcode project + repo from Fundra
- Brian is EXCITED about this — don't let it get lost. Bring it up next session.
