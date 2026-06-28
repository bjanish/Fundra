# Screenshot Sample Data

Use these accounts and amounts when setting up Fundra for App Store screenshots.

## Accounts

- Emergency
- Vacation
- New Car

## Monthly Balances

| Account   | January | February | March  |
|-----------|---------|----------|--------|
| Emergency | $1,800  | $2,100   | $2,450 |
| Vacation  | $2,400  | $2,750   | $3,120 |
| New Car   | $7,200  | $7,950   | $8,750 |

## Totals

| Month    | Total   |
|----------|---------|
| January  | $11,400 |
| February | $12,800 |
| March    | $14,320 |

## Simulator Setup

Before taking screenshots, run this in Terminal to lock the status bar to 9:41:

```
xcrun simctl status_bar booted override --time "9:41"
```

This resets after each Simulator reboot — run it again each time.
