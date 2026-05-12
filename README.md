# XAUUSD Gold EA — Complete Trading System

**Version 1.0 | 2027 Edition**

A professional Expert Advisor for trading Gold (XAUUSD) on MetaTrader 5, designed to grow a $14 account to $40,000 through intelligent compounding and progressive weekly targets.

---

## 🎯 Overview

This EA implements a complete 6-IDEA trading system that combines:
- **IDEA 1**: Automatic key level detection and chart drawing
- **IDEA 2**: Smart Money Concepts (Order Blocks, FVGs, BIAS, Session levels)
- **IDEA 3**: Multi-indicator filter system (ADX, RSI, Stochastic, ATR)
- **IDEA 4**: Advanced protection system (News filter, spread control, session management)
- **IDEA 5**: Dynamic lot sizing with ATR-based risk management
- **IDEA 6**: Complete entry logic with multi-step validation

## 📊 Key Features

### Modern UI Dashboard (2027 Standards)
- Real-time balance and equity tracking
- Weekly target progress monitor
- Live indicator readings (ADX, RSI, Stochastic, ATR)
- Current session and trading status
- Clean, minimalist design with high readability

### Progressive Weekly Targets
```
Week 1:  $14 → $100
Week 2:  $100 → $500
Week 3:  $500 → $1,500
Week 4:  $1,500 → $3,000
Week 5:  $3,000 → $5,000
Week 6:  $5,000 → $7,000
Week 7:  $7,000 → $12,000
Week 8:  $12,000 → $15,000
Week 9:  $15,000 → $20,000
Final:   $20,000 → $40,000
```

### Trade Frequency Control
- **Target**: 1-2 trades per day
- **Weekly**: ~10 quality trades
- Automatic frequency limiting to prevent overtrading
- Quality over quantity approach

### Risk Management
- Dynamic lot sizing based on balance stage
- ATR-based stop loss and take profit
- Automatic trailing stop system
- Breakeven protection
- Partial position closing at key levels
- Daily equity hard stop
- Consecutive loss pause mechanism

### Smart Money Integration
- Order Block detection (bullish/bearish)
- Fair Value Gap (FVG) identification
- BIAS line confirmation
- Session high/low tracking
- Candle pattern recognition (Engulfing, Pin Bars)
- RSI + Stochastic confluence signals

### Advanced Protection
- Trading session hours enforcement (Asian, London, New York)
- Spread filter (max 35 points)
- ATR volatility guard
- News event blocking (high-impact only)
- Slippage protection (max 5 points)
- Daily loss limits

---

## 🚀 Installation

### Step 1: Download the EA
1. Download `XAUUSD_Gold_EA.mq5` from this repository
2. Save it to your MetaTrader 5 data folder

### Step 2: Install in MT5
1. Open MetaTrader 5
2. Click **File → Open Data Folder**
3. Navigate to **MQL5 → Experts**
4. Copy `XAUUSD_Gold_EA.mq5` into this folder
5. Restart MetaTrader 5 or click **Refresh** in Navigator

### Step 3: Compile the EA
1. Open **MetaEditor** (F4 in MT5)
2. Open `XAUUSD_Gold_EA.mq5`
3. Click **Compile** (F7)
4. Verify compilation is successful (0 errors)

### Step 4: Attach to Chart
1. Open a **XAUUSD (Gold)** chart
2. Set timeframe to **M15** (recommended)
3. Drag the EA from Navigator onto the chart
4. Configure settings (see below)
5. Enable **AutoTrading** (Ctrl+E)

---

## ⚙️ Configuration

### Recommended Settings for $14 Starting Balance

```
=== IDEA 1 — Key Level Lines ===
Daily Lookback: 4
Fibonacci Level: 0.68

=== IDEA 3 — Indicator Filters ===
RSI Period: 14
Stochastic K: 14
Stochastic D: 1
Stochastic Slowing: 3
ATR Period: 14
ADX Period: 14

=== IDEA 4 — Protection System ===
Max Spread: 35 points
Max Slippage: 5 points
News Block Before: 15 minutes
News Block After: 15 minutes
ATR Min Threshold: 5.0
ATR Max Threshold: 150.0
Daily Loss Limit (Small): $5.00
Spread Calm Candles Wait: 7

=== IDEA 5 — TP/SL & Risk ===
SL ATR Multiplier: 1.5
TP ATR Multiplier: 3.0
Trailing ATR Multiplier: 1.0
Breakeven Trigger: 1.0 × ATR
Partial Close: 50%
Min SL M1-M5: 20-40 pips
Min SL M15: 40-80 pips

=== IDEA 6 — Entry Control ===
Max Trades/Day (Small): 3
Max Trades/Day (Large): 5
Target Trades/Day: 1.5

=== Progressive Weekly Targets ===
Use Progressive Targets: true
Week 1 Target: $100
Week 2 Target: $500
Week 3 Target: $1,500
Week 4 Target: $3,000
Week 5 Target: $5,000
Week 6 Target: $7,000
Week 7 Target: $12,000
Week 8 Target: $15,000
Week 9 Target: $20,000
Final Target: $40,000

=== UI Settings ===
Show UI: true
UI Background: Black
UI Text Color: White
UI Corner: Left Upper
```

---

## 📈 How It Works

### Entry Process (6-Step Validation)

1. **Protection Check**
   - Inside trading session hours?
   - No high-impact news?
   - Spread below 35 points?
   - Daily loss limit not hit?
   - Max trades per day not reached?

2. **Indicator Filter**
   - ADX > 25 (trending market)
   - ADX not rising above 37 (avoid strong trends)
   - RSI and Stochastic agree on direction
   - ATR within 5-150 points range

3. **Price Near Key Level**
   - Within 0.5 × ATR of:
     - Daily high/low (orange lines)
     - 1H Fibonacci 0.68 (green line)
     - 15M Fibonacci 0.68 (blue line)

4. **Smart Money Confirmation**
   - Order Block present?
   - Fair Value Gap detected?
   - BIAS line confirms?
   - RSI+Stoch confluence dot?
   - Candle pattern arrow?

5. **Direction Decision**
   - BUY: Support level + bullish OB/FVG + oversold
   - SELL: Resistance level + bearish OB/FVG + overbought

6. **Trade Execution**
   - Calculate dynamic lot size
   - Set ATR-based SL and TP
   - Final spread check
   - Send order with slippage protection

### Trade Management

**Breakeven**: When profit reaches 1.0 × ATR, move SL to entry price

**Trailing Stop**:
- Starts when profit reaches 0.5 × ATR
- Trails at 1.0 × ATR distance
- Updates only when change is significant (0.5 × ATR)
- Never moves backward

**Partial Close**:
- Close 50% when first key level is hit
- Remaining 50% continues with trailing stop

**Dynamic Lot Sizing**:
```
Balance $14-$100:    Max 30% risk per trade
Balance $100-$500:   Max 30% risk per trade
Balance $500-$2K:    Max 20% risk per trade
Balance $2K-$10K:    Max 15% risk per trade
Balance $10K-$35K:   Max 10% risk per trade
Balance $35K-$40K:   Max 5% risk per trade (near-target lock)
```

---

## 📅 Trading Sessions

All times in **broker server time**:

- **Asian Session**: 00:00 – 06:00
- **London Session**: 08:00 – 12:00
- **New York Session**: 13:00 – 17:00

EA only opens new trades during these windows. Trades opened during a session can be managed 24/7.

---

## 🎨 Chart Visualization

### Key Level Lines (IDEA 1)
- **Orange (3px)**: Daily High/Low from last ~4 days
- **Light Green (3px)**: 1H Fibonacci 0.68 level
- **Blue (3px)**: 15M Fibonacci 0.68 diagonal trendline

### Smart Money Components (IDEA 2)
- **Session Lines**: Asian (Yellow), London (Lime), New York (Aqua)
- **Confluence Dots**: Green (buy signal), Red (sell signal)
- **Pattern Arrows**: Engulfing and Pin Bar detection
- **FVG Boxes**: Green (bullish gap), Red (bearish gap)
- **BIAS Lines**: Lime (bullish), Red (bearish)
- **Order Blocks**: Green rectangles (bullish OB), Red rectangles (bearish OB)

---

## ⚠️ Important Notes

### Backtesting
- Use **M15 timeframe** for best results
- Set **spread** to realistic values (15-30 points)
- Use **Every tick based on real ticks** model
- Start date: Allow sufficient history (6+ months)
- Initial deposit: $14

### Live Trading
- **Minimum balance**: $14
- **Recommended broker spread**: < 30 points average
- **Account type**: ECN or low-spread account
- **Leverage**: 1:100 or higher recommended
- **VPS**: Recommended for 24/7 operation

### Risk Warning
⚠️ Trading involves substantial risk. Past performance does not guarantee future results. This EA uses aggressive compounding and is designed for experienced traders who understand the risks. Never invest more than you can afford to lose.

### Account Growth Expectations
The growth plan from $14 to $40,000 is **aggressive** and requires:
- Consistent market conditions
- Low spread broker
- Minimal slippage
- 55%+ win rate
- Proper risk management
- No manual intervention

Actual results will vary based on market conditions, broker execution, and other factors.

---

## 🔧 Troubleshooting

### EA Not Trading
1. Check if **AutoTrading** is enabled (button on toolbar)
2. Verify you're inside a **trading session**
3. Check **spread** is below 35 points
4. Review **daily loss limit** hasn't been hit
5. Ensure **max trades per day** not reached
6. Check **journal tab** for error messages

### No UI Displaying
1. Ensure **Show UI** is set to `true`
2. Check **UI settings** are configured correctly
3. Try changing **UI Corner** position
4. Restart MT5 and reattach EA

### Trades Closing Too Early
1. Review **trailing stop** settings
2. Check if hitting **partial close** at key levels
3. Verify **breakeven** trigger is appropriate
4. Adjust **ATR multipliers** if needed

### High Loss Rate
1. Review **entry conditions** — may be too aggressive
2. Check **broker spread** — high spreads reduce profitability
3. Verify **slippage** is within acceptable range
4. Consider adjusting **indicator filters**
5. Backtest with different settings

---

## 📞 Support & Documentation

- **Full Documentation**: See `XAUUSD_EA_Full_Document.md` in this repository
- **Issues**: Report bugs on GitHub Issues
- **Updates**: Watch repository for updates

---

## 📄 License

This Expert Advisor is provided for educational and research purposes. Use at your own risk.

---

## 🎯 Development Roadmap

- [x] Core 6-IDEA system implementation
- [x] Progressive weekly targets
- [x] Modern UI dashboard
- [x] Trade frequency control
- [ ] Enhanced news calendar integration
- [ ] Multi-timeframe confirmation
- [ ] Advanced pattern recognition
- [ ] Machine learning signal optimization
- [ ] Multi-symbol support
- [ ] Cloud-based performance analytics

---

**© 2027 XAUUSD Gold EA System | Advanced Algorithmic Trading**

*Developed following complete specification from XAUUSD_EA_Full_Document.md*