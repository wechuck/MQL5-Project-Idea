# Quick Installation Guide — XAUUSD Gold EA

## Prerequisites
- MetaTrader 5 platform installed
- XAUUSD (Gold) trading enabled on your broker account
- Minimum balance: $14 (recommended: $20-$50 for better risk management)

## Step-by-Step Installation

### 1. Download the EA
Download `XAUUSD_Gold_EA.mq5` from the repository.

### 2. Locate MT5 Data Folder
1. Open MetaTrader 5
2. Go to **File → Open Data Folder**
3. A folder will open (usually: `C:\Users\[YourName]\AppData\Roaming\MetaQuotes\Terminal\[BrokerID]\MQL5`)

### 3. Copy EA File
1. Navigate to the **Experts** subfolder
2. Copy `XAUUSD_Gold_EA.mq5` into this folder

### 4. Compile the EA
1. In MT5, press **F4** to open MetaEditor
2. In Navigator panel (left side), expand **Experts**
3. Double-click `XAUUSD_Gold_EA.mq5` to open it
4. Press **F7** to compile
5. Check the **Toolbox** tab at the bottom for compilation results
6. You should see: **0 error(s), 0 warning(s)**

### 5. Attach EA to Chart
1. In MT5, open a **XAUUSD** chart (File → New Chart → XAUUSD)
2. Set timeframe to **M15** (recommended for optimal performance)
3. In **Navigator** panel, expand **Expert Advisors**
4. Drag **XAUUSD_Gold_EA** onto the XAUUSD chart
5. A settings window will appear

### 6. Configure Settings
Use the recommended settings from the main README, or use these quick defaults:

**For $14-$50 account:**
- Use Progressive Targets: `true`
- Max Spread: `35`
- Show UI: `true`
- All other settings: Leave as default

**For $50-$200 account:**
- Use Progressive Targets: `true`
- Max Spread: `30`
- Daily Loss Limit (Small): `10`
- All other settings: Leave as default

Click **OK** to apply settings.

### 7. Enable Auto-Trading
1. Click the **AutoTrading** button in the toolbar (or press **Ctrl+E**)
2. The button should turn green
3. In the top-right corner of the chart, you should see: 😊 (smiley face)

### 8. Verify Installation
Check for the following:
- **UI panel** should appear in the top-left corner (if Show UI = true)
- **Key level lines** should be drawn on the chart (Orange, Green, Blue)
- **Terminal → Experts** tab should show initialization messages
- No error messages in the **Journal** tab

## Common Setup Issues

### ❌ "Expert Advisor is not certified"
**Solution**: In EA settings, check **Allow DLL imports** and **Allow WebRequest** (both should be enabled).

### ❌ "Trade is not allowed"
**Solution**:
1. Enable AutoTrading (Ctrl+E)
2. Check account allows automated trading
3. Verify XAUUSD symbol is available for trading

### ❌ "Invalid stops"
**Solution**:
1. Your broker may have minimum stop level requirements
2. Increase `SL_ATR_Multiplier` to 2.0 or higher
3. Adjust `MinSL_M15_Pips` to match broker requirements

### ❌ UI not showing
**Solution**:
1. Set `Show UI` to `true` in EA settings
2. Try different `UI Corner` positions
3. Restart MT5

### ❌ No trades being opened
**Solution**:
1. Check current time is within trading sessions (00:00-06:00, 08:00-12:00, 13:00-17:00 broker time)
2. Verify spread is below 35 points
3. Check ADX and other indicators meet entry conditions
4. Review Journal tab for blocking messages

## First Trade Checklist

Before the EA opens its first trade, verify:
- [ ] Balance is at least $14
- [ ] AutoTrading is enabled (green button)
- [ ] Current time is within a trading session
- [ ] Spread is below 35 points (check Market Watch)
- [ ] No major news events in next 15 minutes
- [ ] Chart is on M15 timeframe
- [ ] Key levels are visible on chart
- [ ] UI shows "Status: Active"

## Monitoring Your EA

### What to Watch
- **Today's Trades**: Should not exceed 2 per day
- **Status**: Should show "Active" during sessions
- **Spread**: Should stay below 35 most of the time
- **Balance progression**: Should follow weekly targets

### Daily Routine
1. Check Journal tab for any errors
2. Review trades opened/closed
3. Verify balance is progressing toward weekly target
4. Ensure no manual intervention needed

### Weekly Review
1. Compare actual balance vs. weekly target
2. Review win rate (aim for 55%+)
3. Check average spread during trade execution
4. Adjust settings if necessary

## Support

If you encounter issues:
1. Check **Journal** and **Experts** tabs for error messages
2. Review this installation guide
3. See main README.md for troubleshooting
4. Report issues on GitHub

---

**Ready to Trade!**

Once properly configured, the EA will:
- Automatically detect trading opportunities
- Open 1-2 high-quality trades per day
- Manage positions with trailing stops
- Progress toward weekly targets
- Protect your account with multiple safety filters

**Important**: Monitor the EA for the first few days to ensure it's working as expected.

Good luck! 🚀
