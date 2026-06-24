# Changelog — Version 1.1

## User-Facing Changes
1. Delete last month → resets app to onboarding (deletes all categories)
2. Warning alert with ⚠️ emoji when deleting the last month
3. Record button color: softer pastel green in light mode
4. Growth view labels rewritten: "Month (first recorded)", "Month (prior month)" with inline delta, "Month (current)", "Total growth from X to Y:"

## Developer-Only (DEBUG, not shipped)
5. Screenshot mode flag — seeds 3 accounts with 3 months of data on launch
6. Face ID bypass in screenshot mode
7. Auto-re-seeds when onboarding appears (no rebuild needed)

## Project/Docs
8. `.gitignore` created (Xcode, macOS, screenshot files)
9. `ScreenshotData.md` — reference data for screenshots
10. `screenshot-mockup.html` — HTML mockup for App Store framing
11. `WhatsNew-1.1.md` — release note draft
12. "Releasing an Update" section added to `XcodeCloudSubmission.md`
13. Steering file updated with new design decisions and completed TODOs
14. Kiro hook: remind to run tests when ContentView/Item.swift is saved
15. Monthly reminder notification — fires on the 1st at 9 AM; permission requested once after first Record save (no settings UI)
16. Rename account from Edit Balance sheet — pencil icon next to account name for inline rename
17. 6-account limit — Add Account button grayed out at cap, onboarding hides "Add another" at 6, caption shown at limit
18. Chart x-axis label truncation — sliding scale: 9 chars at 6 accounts, 11 at 5, full name at 4 or fewer
19. Growth line chart: catmullRom smooth curve interpolation; light mode dots changed to warm goldenrod (0.62, 0.52, 0.25); dashed y-axis grid lines (lineWidth 0.5, dash [4], gray 0.4 opacity)
20. Growth button color: dark mode muted blue (0.43, 0.60, 0.76), light mode deeper blue (0.30, 0.45, 0.60)
21. Bar chart: 6 muted color palette (light/dark variants), 6pt corner radius, abbreviated amount annotations above bars, 230pt height, gray background card (0.20 opacity, 12pt radius); single-account constrained to 200pt width
22. Bar chart animation: bars grow from zero on appear/period change
23. Animated total: numericText content transition (34pt bold moneyGreen, 0.6s easeInOut)
24. Month navigation: chevron arrows with light haptic, easeInOut 0.3s; date format: month (wide), day, year
25. Undo toast on month delete: 5-second window, black 0.85 pill, blue Undo button, slides from bottom
26. Main screen background: dark mode custom near-black (0.11, 0.11, 0.12)
27. Export/Save Chart row: gray capsule background (0.08 opacity, 8pt corner radius)
28. Add Account button: matches Growth button blue color scheme; grayed at limit
29. Fundra title: 28pt bold italic, muted blue, subtle shadow (black 0.1, blur 2, y 1)
30. Dashed y-axis grid lines on main bar chart (lineWidth 0.5, dash [4], gray 0.4 opacity)
31. Quote section styling: fade-out 0.2s easeOut / fade-in 0.3s easeIn; footnote italic text, caption author centered, 260pt width constraint; refresh icon at 50% secondary opacity
32. Edit Balance rename: "Done" button turns blue only when account name has actually changed; shows secondary/gray otherwise
33. Growth summary: divider added between summary text and line chart; spacing balanced — matches above/below both dividers
34. Debug toggle: simplified to 2-state (dark ↔ light), starts from system setting, icon shows destination (sun in dark, moon in light)
35. Edit Balance: "Done" rename link turns blue only when name has changed; full-width separator fix via listRowSeparatorLeading alignment guide
36. Growth chart light mode dots: changed from reddish-amber to dark gold (0.55, 0.47, 0.18) for clearer gold appearance
37. Growth summary divider spacing: refactored to explicit padding (outer VStack spacing: 0); both dividers have 12pt above, second divider has 24pt below to visually match due to chart internal margins
38. Growth line chart: wrapped in rounded gray card (12pt corners, 0.1 opacity background, 24pt top / 16pt sides+bottom inner padding)
39. Growth chart x-axis: fixed duplicate month labels by using explicit data point dates as axis mark values
40. Separated screenshotMode and debugMode — both behind #if DEBUG; screenshotMode = clean production look with seeded data; debugMode = same + debug overlays (dark/light toggle)
41. DatePicker date restriction bypassed in both screenshot and debug modes
42. Easter egg: 3rd-tap wiggle upgraded to earthquake jiggle — fixed 10-step diagonal pattern (±5–7pt x/y), 40–50ms per step, rigid haptic on each shake
43. Updated App Store keywords: dropped "chart" and "personal"; added "offline", "private", "simple", "goal", "monthly" (95/100 chars used)
