# Screenshot Captions

## 1. Main view (light)
**Heading:** Your savings at a glance
**Subheading:** See all your accounts in one place
**Background:** #82AFA4
**Text:** Black

## 2. Growth Summary (light)
**Heading:** Watch your savings grow
**Subheading:** Month-over-month progress at your fingertips
**Background:** #82AFA4
**Text:** Black

## 3. Record month (light)
**Heading:** Track every month in seconds
**Subheading:** One tap to update all your balances
**Background:** #82AFA4
**Text:** Black

## 4. Main view (dark)
**Heading:** Beautiful in light and dark
**Subheading:** Easy on the eyes, day or night
**Background:** #2A3A38
**Text:** White

## 5. Growth Summary (dark)
**Heading:** Watch your savings grow
**Subheading:** Month-over-month progress at your fingertips
**Background:** #2A3A38
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

7. Take screenshots. To clear the override later:
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


