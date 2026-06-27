# Changelog — Version 1.2

## User-Facing Changes
1. Onboarding: account name suggestions shown below each empty input field (e.g., Savings, Vacation, Emergency, New Car, Roth IRA, Cash)
2. Onboarding: placeholder text changed from "Account name" to "Name"
3. Onboarding: subtitle simplified ("Add your savings to get started")
4. Onboarding: "＋ Add another" button in Fundra muted blue
5. Onboarding: input field spacing increased (12pt → 15pt)
6. Onboarding: "Get Started" button resized from .large to .regular, 24pt top padding
7. Onboarding: logo bar chart animates with subtle random height changes (staircase shape preserved)

## Easter Egg / Polish
8. Export/Save Chart icons animate in sync with title tap (deflate + rebuild)
9. Confetti doubled (80 particles)
10. Record sheet: muted blue ringed dot before "Record date" label (matches Growth chart dot style)
11. Record sheet: DatePicker tinted to Fundra muted blue (matches dot, cohesive color story)

## Developer-Only
10. MiniBarChartIcon: added `animating` parameter for deflate/rebuild support
11. Bug fix: `hasSeeded` flag prevents screenshot/debug re-seed loop on delete-last-month
