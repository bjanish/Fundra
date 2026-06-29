# Changelog — Version 1.2.1 (pending — submit July 1)

## User-Facing Changes
1. Edit Balance: rename field now uses rounded border style (matches onboarding text fields)
2. Edit Balance: rename field auto-focuses with cursor when pencil is tapped
3. Lock screen: branded with mini bar chart icon + "Fundra" in 28pt bold italic muted blue with shadow (matches main screen)
4. Growth Summary: preview chart shown when viewing the first month (replaces "Close and swipe" dead-end message)
5. Home screen widget (small + medium): shows total savings in moneyGreen, Fundra branding with 3-bar icon, last recorded month; adaptive background (white light / near-black dark); refreshes after each Record save
6. Manage Account (long-press rename): rounded border field + auto-focus (matches Edit Balance pencil rename)

## Developer-Only
6. Screenshot mode: DatePicker restricted to Apr 15, 2026 (matches production behavior)
7. App review prompt: triggers on 3rd and 6th Record save (AppStore.requestReview(in:), simple counter via AppStorage)
8. SwiftData moved to shared App Group container (group.com.fundra.shared) for widget access; migration copies existing store on first launch
9. WidgetCenter.shared.reloadAllTimelines() called after Record save
