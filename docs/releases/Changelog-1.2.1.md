# Changelog — Version 1.2.1 (pending — submit July 1)

## User-Facing Changes
1. Edit Balance: rename field now uses rounded border style (matches onboarding text fields)
2. Edit Balance: rename field auto-focuses with cursor when pencil is tapped
3. Lock screen: branded with mini bar chart icon + "Fundra" in 28pt bold italic muted blue with shadow (matches main screen)
4. Growth Summary: preview chart shown when viewing the first month (replaces "Close and swipe" dead-end message)

## Developer-Only
5. Screenshot mode: DatePicker restricted to Apr 15, 2026 (matches production behavior)
6. App review prompt: triggers at 3 and 6 unique months recorded (SKStoreReviewController, AppStorage flags to prevent repeat)
