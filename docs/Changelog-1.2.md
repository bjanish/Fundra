# Changelog — Version 1.2

## User-Facing Changes
1. Onboarding: account name suggestions shown below each empty input field (e.g., Savings, Vacation, Emergency, New Car, Roth IRA, Cash)
2. Onboarding: placeholder text changed from "Account name" to "Name"
3. Onboarding: subtitle simplified ("Add your savings to get started")
4. Onboarding: "＋ Add another" button in Fundra muted blue
5. Onboarding: input field spacing increased (12pt → 15pt)
6. Onboarding: "Get Started" button resized from .large to .regular, 24pt top padding
7. Onboarding: logo bar chart animates with subtle random height changes (staircase shape preserved)
8. Onboarding: suggestion text reserves space (opacity 0) when field has input — prevents layout jump
9. Onboarding: tap outside text fields dismisses keyboard
10. Onboarding: "Get Started" button pinned 30pt below inputs (no Spacer push to bottom)
11. Onboarding: wave animation on "Welcome to Fundra" title (letters bounce sequentially on appear)
12. Onboarding: text fields use custom rounded style (10pt corner radius, plain style with stroke border)

## Easter Egg / Polish
8. Export/Save Chart icons animate in sync with title tap (deflate + rebuild)
9. Confetti doubled (80 particles)
10. Record sheet: muted blue ringed dot before "Record date" label (matches Growth chart dot style)
11. Record sheet: DatePicker tinted to Fundra muted blue
12. Growth Summary: sample preview chart (4 months, gold dots, dimmed) shown when only 1 month recorded — fills empty state with a teaser
13. Onboarding: remove button softened from red to muted gray (secondary 0.5 opacity)
14. Growth sample chart: area fill bumped to 0.18 in light mode for more visibility (dark stays 0.08)

## Developer-Only
10. MiniBarChartIcon: added `animating` parameter for deflate/rebuild support
11. Bug fix: `hasSeeded` flag prevents screenshot/debug re-seed loop on delete-last-month
