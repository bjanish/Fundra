# Screenshot Captions

## 1. Main view (light)
**Heading:** Your savings at a glance
**Subheading:** See all your accounts in one place
**Background:** #567F75
**Text:** White

## 2. Main view (dark)
**Heading:** Looks great, always
**Subheading:** Built for both modes
**Background:** #567F75
**Text:** White

## 3. Growth Summary (light)
**Heading:** Track your growth
**Subheading:** Monthly progress, visualized
**Background:** #567F75
**Text:** White

## 4. Record (light/dark)
**Heading:** Log months fast
**Subheading:** Update all at once
**Background:** #567F75
**Text:** White

## 5. Widget (home screen)
**Heading:** Always on your home screen
**Subheading:** (none)
**Background:** #567F75
**Text:** White

---

## Screenshot Setup Recipe

### Status Bar Override (9:41 time)

1. Kill all simulators:
   ```bash
   xcrun simctl shutdown all
   killall Simulator
   ```

2. Boot fresh:
   ```bash
   open -a Simulator
   ```

3. Set the device to iPhone 17 in Simulator (or select it in Xcode's scheme).

4. Apply status bar override:
   ```bash
   xcrun simctl status_bar booted override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
   ```

5. Build and run Fundra (⌘R) targeting that simulator.

6. Put the app in screenshot mode before building:
   - `screenshotMode = true`, `debugMode = false` in ContentView.swift

7. Take screenshots (File → Save Screen or ⌘+S in Simulator). Saves to Desktop.

8. To clear the override later:
   ```bash
   xcrun simctl status_bar booted clear
   ```

### Quick Copy-Paste (the sequence that worked)

```bash
killall Simulator
open -a Simulator
xcrun simctl status_bar booted override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
```

### Notes
- Confirmed working on iPhone 17 simulator (iOS 27)
- `simctl status_bar` can be unreliable on newer runtimes — if it stops working, try killing and rebooting the sim
- Widget screenshot: add widget to home screen manually (long-press → + → search "Fundra")
- Framing tool: appshots.appstore.xyz
