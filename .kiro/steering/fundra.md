# Fundra Project Context

## App Overview
- Fundra is a privacy-first iOS savings tracker (iPhone-only, portrait-only)
- Built with SwiftUI, SwiftData, Swift Charts
- Fully offline — no network, no analytics, no accounts
- Target: iOS 18+, Xcode 27, launched June 23, 2026

## Architecture
- Single file: ContentView.swift (all views)
- Models: Category and Balance (in Item.swift)
- Face ID/Touch ID lock on launch (FundraApp.swift)
- Docs and non-code files live in `docs/` folder
- Project uses no external dependencies (pure Apple frameworks)

## Design Decisions
- Forest green (#385C57) for dollar amounts
- Muted blue (#6E98C2) for branding
- Record button: bold text, darker/richer green in both modes, subtle green-tinted shadow
- Sheet Save/Add buttons: deeper navy blue (0.22, 0.38, 0.55) with matching blue-tinted shadow, explicit white text (forced via label's .foregroundStyle to override .borderedProminent in dark mode) — same polish level as Record but in the blue family
- MiniBarChartIcon used in all sheet headers (bar chart icon)
- MiniLineChartIcon used on Growth button (line chart icon in moneyGreen, same size/weight as Accounts header — Growth is an equal peer, not subordinate)
- Accounts sorted lowest-to-highest balance
- Account names in dark charcoal (Color(white: 0.35)) for hierarchy under bold header
- "Accounts" header toned down in dark mode (75% white instead of full white)
- Bar chart with tap-to-edit (hidden shortcut)
- Bar chart styling: 6 muted color palette (different for light/dark), 6pt corner radius, abbreviated amount annotations above bars, 230pt height, gray background card (0.20 opacity, 12pt corner radius); single-account chart constrained to 200pt width
- Bar chart animations: bars grow from zero on appear and period change; title tap deflates and rebuilds with spring
- Main bar chart axes: y-axis uses .footnote font size; x-axis keeps custom size (10pt semibold) for truncation; default system colors; dashed y-axis grid lines (lineWidth 0.5, dash [4], gray 0.4 opacity)
- Month navigation: chevron arrows with light haptic feedback, easeInOut 0.3s transition; date in subheadline (month wide, day, year)
- Total amount: animated numericText content transition (0.6s easeInOut); 34pt bold in moneyGreen
- Undo toast on month delete: 5-second window, black 0.85 opacity pill, blue "Undo" button, slides up from bottom
- Main screen background: dark mode custom near-black (0.11, 0.11, 0.12), light mode system background
- Export/Save Chart row: gray capsule background (0.08 opacity, 8pt corner radius), caption font, secondary color
- Add Account button: matches Growth button color scheme (muted blue light/dark); grayed at 6-account limit
- Fundra title: 28pt bold italic, muted blue, subtle shadow (black 0.1, 2pt blur, 1pt y-offset)
- Long-press context menu on account rows for Rename/Delete
- Long-press date to delete month (triggers heavy haptic feedback + confirmation alert)
- Export/Save Chart positioned below the chart (not in account list)
- Quote section: minimal styling, no bubble/shadow, just text + refresh icon; fade-out (0.2s easeOut) / fade-in (0.3s easeIn) animation on refresh; footnote italic text, caption author centered, constrained to 260pt width; refresh icon at 50% secondary opacity
- Easter egg: tap Fundra title → bars deflate and rebuild with spring animation; Export/Save Chart icons also deflate/rebuild in sync; every 3rd tap triggers confetti (80 particles) + earthquake jiggle (fixed 10-step diagonal pattern, ±6–7pt, rigid haptic bursts)
- One-time tooltip: "Tip: Long-press an account to rename or delete it." (auto-dismisses after 10s, uses @AppStorage)
- Onboarding: larger 3-bar icon above title with subtle animated height randomization (staircase shape always preserved — bar ranges: 6–9, 12–16, 19–22; 2s interval, 1.2s easeInOut transitions), "Fundra" in italic muted blue (#6E98C2), subtitle "Add your savings to get started" in secondary
- Onboarding: account name suggestions below empty fields (e.g., Savings, Vacation, Emergency, New Car, Roth IRA, Cash) — 6 unique suggestions matching max 6 accounts
- Onboarding: placeholder text "Name" (not "Account name"), input spacing 15pt, "＋ Add another" in muted blue
- Onboarding: "Get Started" button uses .controlSize(.regular), 24pt top padding above it
- Record sheet: muted blue ringed dot (10pt outer stroke, 5pt inner fill) before "Record date" label — same dot style as Growth chart, ties the sheet to Fundra branding; DatePicker tinted to matching muted blue (cohesive with dot)
- Record pre-fills amounts when editing an existing month; shows previous month's values as gray placeholder text for new months
- Monthly reminder notification: fires on the 1st of every month at 9 AM ("Time to record — update your savings totals in Fundra"). Permission requested once after first Record save, stored in @AppStorage. No settings UI — users manage via iOS Settings if they want to disable.
- Edit Balance sheet: pencil icon next to account name for inline rename (discoverable path; long-press context menu stays as power-user path); "Done" button turns blue only when name has changed

## Validation Rules
- Record: all fields required, at least one > 0, zeros allowed
- Add Account: name + amount required, amount must be > 0
- Edit Balance: zero allowed
- 15-char limit on account names
- Maximum 6 accounts — "Add Account" grayed out at limit, onboarding hides "Add another" at 6, caption "6 account limit reached" shown
- Chart x-axis labels: dynamic truncation based on account count (6→9 chars, 5→11 chars, 4 or fewer→full name)
- No duplicate names (case-insensitive) — checked in onboarding and Add Account
- Onboarding shows "Already added" warning for duplicate names in real-time
- No future dates
- Single decimal point, max 2 decimal places
- Input filter strips letters, special chars, multiple dots

## Interaction Patterns
- Tap account row → Edit Balance (or opens Record if no balance for that month)
- Long-press account row → context menu (Rename, Delete)
- Long-press date → Delete Month confirmation
- Tap chart bar → Edit Balance (hidden shortcut)
- Delete last account warns "This is your last account. Deleting it will reset the app to setup."
- Delete last month warns "⚠️ Delete Month?" with "This is your last month. Deleting it will reset the app to setup." — then resets to onboarding
- Growth view labels: "Month (first recorded)", "Month (prior month)" with month-over-month delta inline, "Month (current)", then "Total growth from X to Y:" at bottom
- Growth line chart: green line + area fill with catmullRom smooth curves; dark mode uses subdued goldenrod dots (0.65, 0.55, 0.30) and y-axis labels with lighter gold x-axis months (0.75, 0.65, 0.38); light mode uses golden-yellow dots (0.75, 0.63, 0.0) and dark green (0.20, 0.40, 0.28) for all axis labels; axis font size: .footnote; y-axis labels have 6px trailing padding; dashed grid lines (lineWidth 0.5, dash [4], gray 0.4 opacity)
- Growth summary layout: divider between summary text and line chart; consistent spacing — no extra top padding above second divider, 12pt above / 24pt below second divider; line chart in rounded gray card (12pt corners, 0.1 opacity, 24pt top padding, 16pt sides/bottom)
- Growth button: same size/weight as Accounts header (19pt bold); dark mode muted blue (0.43, 0.60, 0.76), light mode deeper blue (0.30, 0.45, 0.60)
- Screenshot mode: `#if DEBUG` flag in ContentView.swift — seeds data, skips Face ID, no date restriction. Looks exactly like production (no debug overlays). Toggle by setting `screenshotMode = true/false`.
- Debug mode: `#if DEBUG` flag in ContentView.swift — everything screenshot mode does, plus debug overlays (dark/light toggle). Toggle by setting `debugMode = true/false`.
- Production mode: both flags false — Face ID required, no seeded data, future dates restricted on DatePicker. App behaves exactly as shipped.
- Debug mode includes a floating dark/light mode toggle (top-left corner) — single tap switches between dark and light. No need to change Simulator settings.

## User Preferences
- Brian prefers practical solutions over theoretical ones
- Likes to discuss trade-offs before committing
- Appreciates when I proactively find issues
- Prefers short, direct answers unless exploring options
- Update steering file automatically for any user-facing design change (visual, haptic, layout, color, interaction — any UI change)
- Describe file locations simply (e.g., ".kiro → steering directory")
- Uses "debug mode" to mean toggling `debugMode` in ContentView.swift
- Uses "screenshot mode" to mean toggling `screenshotMode` in ContentView.swift
- Uses "turn off/on debug mode" as shorthand — just flip the bool
- Uses "use my data" to mean `useRealisticData = true`; "use growth data" to mean `useRealisticData = false`
- Uses "put it in screenshot mode" to mean: set `screenshotMode = true`, `debugMode = false` (always uses growth data regardless of useRealisticData)
- Uses "put it in debug mode" to mean: set `screenshotMode = false`, `debugMode = true`, don't change useRealisticData
- Uses "put it in production mode" to mean: set `screenshotMode = false`, `debugMode = false`, and `useRealisticData = true`
- Occasionally types fast and makes typos — don't correct them, just understand intent
- Asks "is that normal?" about App Store/Xcode behaviors — give reassurance with context
- Likes to validate ideas verbally before committing to code
- Appreciates when I explain *why* something works, not just *how*
- Will say "update steering" as a reminder, but prefers I do it proactively for design changes
- When updating steering, also update the relevant changelog (e.g., `docs/Changelog-1.2.md`) with a matching entry
- Conversational style: casual, curious, asks good follow-up questions
- Says "Done." as the signal to rebuild — don't say it prematurely
- Next priority: ship v1.2, then Goals feature (Pro, v2)

## Testing
- Unit tests exist in FundraTests for: filterAmountInput, abbreviatedAmount, formatFullAmount
- After modifying validation or formatting logic, remind Brian to run tests (⌘U in Xcode)

## TODO Before Release
- ~~Re-add date restriction on Record DatePicker~~ ✅ Done (no longer relevant — debug mode handles testing)
- ~~Submit to App Store~~ ✅ Submitted via Xcode Cloud (Xcode 26.5 RC)
- ~~Submit v1.1~~ ✅ Submitted for review
- ~~Submit v1.1.1~~ ✅ Live on App Store

## Deployment
- GitHub repo: github.com/bjanish/Fundra (private)
- Xcode Cloud workflow: "Release" — Archive + App Store Connect distribution; manual start only (auto-trigger disabled via custom rule)
- Xcode version for builds: Xcode 26.5 RC (required — project format downgraded to objectVersion 70 for compatibility)
- Release checklist lives in `docs/XcodeCloudSubmission.md` (includes "Releasing an Update" section)
- Screenshot framing tool: appshots.appstore.xyz; captions/colors in `docs/ScreenshotCaptions.md`
- Current App Store status: v1.1.1 live (v1.0 also available)
- v1.1 changes tracked in `docs/Changelog-1.1.md`
- v1.2 changes tracked in `docs/Changelog-1.2.md`
- Next version: 1.2 (onboarding polish, ready to submit), then 2.0 (Goals feature, Pro tier) — use `git checkout -b v2.0` to start
- Manual release preferred for future submissions (gives window to reject before going live)
- Screenshot mode seeds Record date to Apr 15, 2026 for neutral date display

## Git Reminders
- Remind Brian to commit after any meaningful code change (don't let work pile up uncommitted)
- Remind Brian to push after committing (Xcode Cloud builds from the repo)
- After submitting a version: tag it (e.g., `git tag v1.1`) and push the tag (`git push origin v1.1`)
- Before starting a new major version: create a branch (e.g., `git checkout -b v2.0`)
- If Brian says "I'm done for today" or wraps up a session with changes, remind him to commit + push
- Never assume Git operations happened — always ask or remind
- **Before every push:** check `objectVersion` in project.pbxproj — Xcode 27 silently upgrades it to 110. Must be 70 for Xcode Cloud (26.5). If it's 110, change it back to 70 before pushing.

## Known Development Issues
- Xcode 27 beta Debug builds have a "System gesture gate timed out" issue causing ~2s delay on first long-press gestures. This does NOT affect Release/App Store builds. It's an Apple beta bug.
- `hasSeeded` flag in ContentView prevents screenshot/debug mode from re-seeding data after user deletes last month (avoids SwiftData thrashing loop)
- `.chartXSelection` API was tested but reverted — requires double-tap sometimes. Keeping `.chartOverlay` approach for chart tap-to-edit.

## App Store Performance
- Launched: June 23, 2026
- 16 first-time downloads in first 3 days (organic, no paid marketing)
- 7.46% conversion rate (well above ~2-4% App Store average)
- 454 impressions, 70 product page views

### Version 2 (Pro)
- Locale-aware currency formatting (use device locale, replace all hardcoded `$`) — do this FIRST before Goals
- Goals feature
- Cumulative monthly bar chart — each bar = total savings across all accounts for that month; shows overall savings trajectory at a glance
- Horizontal bar chart option — scales better for many accounts, potential Pro feature to lift 6-account limit
- Design polish pass — spacing, typography hierarchy, animations, dark mode refinement, empty states
- Pro unlock: one-time IAP (~$3.99), NOT subscription — matches app philosophy (simple, honest, no recurring anxiety)
- Pro bundle (TBD, finalize before coding): Goals + cumulative chart + possibly unlimited accounts
- HYSA rate feature — show current high-yield savings rates + projected earnings based on user's total balance (e.g., "Your $19,120 could earn ~$860/year at 4.5% APY"). Needs API research. Could justify subscription if live data has ongoing cost.
- HYSA monetization: include personal referral link from day one (earns per funded account, $50–$200 each). Scale to direct bank sponsorship when downloads grow. Referral works at any user count — don't wait.
