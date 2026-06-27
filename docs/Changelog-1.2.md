# Changelog — Version 1.2

## User-Facing Changes
1. Onboarding: account name suggestions shown below each empty input field (e.g., Savings, Vacation, Emergency, New Car, Roth IRA, Cash)
2. Onboarding: placeholder text changed from "Account name" to "Name"
3. Onboarding: subtitle simplified ("Add your savings to get started")
4. Onboarding: "Add another" button uses `plus.circle` SF Symbol in Fundra muted blue
5. Onboarding: input field spacing increased (12pt → 15pt)
6. Onboarding: "Get Started" button resized from .large to .regular, 30pt top padding, pinned below inputs
7. Onboarding: logo bar chart animates with subtle random height changes (staircase shape preserved)
8. Onboarding: suggestion text reserves space (opacity 0) when field has input — prevents layout jump
9. Onboarding: tap outside text fields dismisses keyboard (contentShape + onTapGesture)
10. Onboarding: wave animation on "Welcome to Fundra" title (letters bounce -10pt sequentially, 0.06s stagger, 0.25s easeInOut, 0.8s initial delay)
11. Onboarding: keyboard appears after wave animation completes (+0.2s buffer)
12. Onboarding: text fields use custom rounded style (10pt corner radius, plain style with stroke border)
13. Onboarding: remove button softened from red to muted gray (secondary 0.5 opacity)

## Easter Egg / Polish
14. Export/Save Chart icons animate in sync with title tap (deflate + rebuild)
15. Confetti doubled (80 particles)
16. Record sheet: muted blue ringed dot before "Record date" label (matches Growth chart dot style)
17. Record sheet: DatePicker tinted to Fundra muted blue
18. Growth Summary: sample preview chart (4 months, gold dots, dimmed at 50% opacity) shown when only 1 month recorded — fills empty state with a teaser
19. Growth sample chart: area fill 0.18 in light mode / 0.08 in dark mode

## Developer-Only
20. MiniBarChartIcon: added `animating` parameter for deflate/rebuild support
21. Bug fix: `hasSeeded` flag prevents screenshot/debug re-seed loop on delete-last-month
22. Simplified release checklist — removed unnecessary screenshot mode toggle steps
