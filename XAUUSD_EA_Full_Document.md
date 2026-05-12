# XAUUSD Gold EA — Full System Document
**Version 1.0 | For MQL5 Development | Claude Opus 4.7 Reference**

---

## Overview

This document describes a complete Expert Advisor (EA) system for trading XAUUSD (Gold) on MetaTrader 5. The system is built across 6 ideas that work together as one flow: drawing key levels, confirming with Smart Money concepts, filtering with indicators, protecting against dangerous conditions, managing trade size and exits, and triggering entries. The EA targets growth from a $14 starting balance to $40,000 through dynamic compounding over approximately 80–100 trading days.

---

## IDEA 1 — Key Level Lines (Chart Drawing)

### Purpose
Automatically draw and maintain 3 key reference lines on the chart. These lines are the foundation — all other ideas react to them.

### Shared Rules for All 3 Lines
- Thickness: **3px — thin and clean**
- Style: **Solid**
- Extend: **Both left and right**
- No price labels on any line
- All lines refresh automatically on new bar (OnCalculate — new bar event)
- Visible on: **M15, M5, M1** timeframes

### Line 1 — Orange Horizontal (Daily)
- Timeframe: 1 Day
- Color: Orange
- Draws **2 lines simultaneously** — the highest high AND the lowest low
- Looks back a maximum of **~4 days** (not strict — uses nearest swing high and swing low)
- If a new daily high or new daily low forms, the line updates to that new level
- When price closes completely through a line, that line is no longer valid as support/resistance

### Line 2 — White/Green Horizontal (1H)
- Timeframe: 1 Hour
- Color: White/Light Green
- Drawn using **Trend-Based Fib Extension** calculation on 1H
- Level used: **0.68 Fibonacci level**
- Refreshes on new 1H bar

### Line 3 — Blue Diagonal Trendline (15M)
- Timeframe: 15 Minutes
- Color: Blue
- Drawn using **Trend-Based Fib Extension** calculation on 15M
- Level used: **0.68 Fibonacci level**
- Diagonal — follows the trend direction
- Refreshes on new 15M bar

---

## IDEA 2 — Smart Money Components (Chart Confirmation Tools)

### Purpose
Draw Smart Money concepts on the chart to confirm that key levels from Idea 1 are being respected. All components are visible on M15, M5, and M1. All refresh on every tick (OnTick).

### Component A — Session High/Low Lines
- Draws the high and low of each trading session automatically
- **Asian Session:** 00:00 – 06:00 broker server time
- **London Session:** 08:00 – 12:00 broker server time
- **New York Session:** 13:00 – 17:00 broker server time
- Each session gets a different color
- Refreshes at the open of each new session

### Component B — RSI + Stochastic Confluence Dot
- Plots a small dot directly on the candle when RSI 14 and Stochastic 14,1,3 both agree
- **Oversold dot (buy signal dot):** RSI below 30 AND Stoch below 20 at the same time
- **Overbought dot (sell signal dot):** RSI above 70 AND Stoch above 80 at the same time

### Component C — Candle Pattern Arrow
- Detects strong candle patterns near Idea 1 lines
- Patterns detected:
  - **Bullish Engulfing:** Current bullish candle body fully engulfs previous bearish candle body
  - **Bearish Engulfing:** Current bearish candle body fully engulfs previous bullish candle body
  - **Pin Bar / Rejection Wick:** Candle wick is at least 2× the size of the candle body
- Plots a small arrow on the candle when pattern is confirmed near an Idea 1 line

### Component D — Fair Value Gap (FVG) Box
- Detects gaps between 3 consecutive candles
- **Bullish FVG:** Candle 3 low is higher than Candle 1 high → Green box drawn in the gap
- **Bearish FVG:** Candle 3 high is lower than Candle 1 low → Red box drawn in the gap
- Box size: **15px wide × 15px height** — small and clean
- Box is removed automatically when price closes back through the gap

### Component E — BIAS Line
- Drawn between candles, 3px thick
- **Bullish BIAS:** Current candle body closes above the previous candle high
- **Bearish BIAS:** Current candle body closes below the previous candle low
- Updates on every tick

### Component F — Order Block
- **Bullish Order Block:** The last bearish candle before a strong bullish impulse move up
- **Bearish Order Block:** The last bullish candle before a strong bearish impulse move down
- Impulse move must be at least **1.5× ATR(14)** in size to confirm the block is valid
- Block is drawn from that candle's high to its low
- Block is removed automatically when price closes completely through it

---

## IDEA 3 — Indicator Filter System

### Purpose
Four indicators work together as a filter on M15. They confirm whether conditions are right before any entry is allowed. No single indicator acts alone — all must agree.

### Timeframe
All 4 indicators run on **M15**. Refresh: every tick.

### ADX 14 — Trend Strength Filter
- ADX below 20 → market is ranging → **block all entries**
- ADX above 25 → trend emerging → start watching
- ADX above 25, +DI above −DI → bullish trend direction
- ADX above 25, −DI above +DI → bearish trend direction
- ADX rising above 37 → strong trend running → **wait, do not enter yet**
- ADX peaked at 37–40 and now falling toward 10–15 → trend just exhausted → **entry signal forming**
- ADX turning down from above 30 → trend losing momentum

### RSI 14 — Momentum Confirmation
- RSI above 70 → overbought, uptrend exhausted → look for sell
- RSI below 30 → oversold, downtrend exhausted → look for buy
- RSI divergence (price makes new high but RSI does not) → additional warning, avoid entry
- Must always agree with ADX direction

### Stochastic 14,1,3 — Entry Timing Confirmation
- Stoch above 80 → overbought confirmation → sell timing
- Stoch below 20 → oversold confirmation → buy timing
- Must agree with RSI at the same time — both must confirm together

### ATR 14 — Volatility Filter
- ATR below 5 points → market is dead flat → **block all entries**
- ATR above 150 points → extreme volatility spike → **block all entries**
- ATR also used in Order Block impulse validation: impulse must be ≥ 1.5× ATR
- ATR also used in trailing stop and SL calculations (see Idea 5)

### Combined Signal Rules

| ADX Condition | RSI + Stoch Condition | Signal |
|---|---|---|
| ADX below 20 | Any | Skip — no trend |
| ADX rising above 37 | Any extreme | Wait — trend still running |
| ADX peaked 37–40, now falling toward 10–15 | RSI above 70, Stoch above 80 | **Strong SELL confirmed** |
| ADX peaked 37–40, now falling toward 10–15 | RSI below 30, Stoch below 20 | **Strong BUY confirmed** |
| ADX above 25, +DI above −DI, RSI below 50, Stoch rising from below 20 | Bullish agreement | **Bullish conditions confirmed** |
| ADX above 25, −DI above +DI, RSI above 50, Stoch falling from above 80 | Bearish agreement | **Bearish conditions confirmed** |

---

## IDEA 4 — Protection System

### Purpose
Block the EA from opening new trades during dangerous market conditions. Protection only blocks new entries — it never interferes with open trade management, trailing stops, or exits.

### Trading Session Hours
EA only opens new trades during these windows (broker server time):
- **Asian Session:** 00:00 – 06:00
- **London Session:** 08:00 – 12:00
- **New York Session:** 13:00 – 17:00
- Outside these hours → no new entries allowed

### Max Trades Per Day
- Balance $14–$100: Maximum **3 trades per day**
- Balance $100 and above: Maximum **5 trades per day**

### Protection 1 — News Filter
- Uses MT5 built-in Economic Calendar API (no external DLL needed)
- Filters: USD and XAU high-impact news events only
- Block window: **15 minutes before** and **15 minutes after** every high-impact event
- Cache-based calendar check — fast, does not slow the EA
- Works in both live trading and backtesting

### Protection 2 — Spread Filter
- Maximum spread allowed at entry: **35 points**
- If spread exceeds 35 points → block entry
- After spread returns to normal, wait an additional **7 candles** before re-enabling entries

### Protection 3 — Slippage Protector
- Maximum slippage tolerance: **5 points**
- If the fill price is more than 5 points away from the signal price → cancel the order
- Prevents bad fills during volatile spikes

### Protection 4 — Daily Equity Hard Stop
- If account equity drops **more than $5 in one day** (small account under $100) → stop all trading for the day
- For larger accounts: daily loss cap scales proportionally with balance
- Resets automatically on the next trading day

### Protection 5 — ATR Volatility Guard
- If ATR drops below 5 points → block entry (dead market)
- If ATR spikes above 150 points → block entry (extreme spike)
- This is a pure block — separate from the ATR signal use in Idea 3

### Protection Priority Order

| Check | If Condition Met | Action |
|---|---|---|
| Outside session hours | Yes | Block entry |
| News window active | Yes | Block entry |
| Spread above 35 points | Yes | Block entry |
| Slippage above 5 points | Yes | Cancel order |
| Daily equity loss limit hit | Yes | Stop all trading for day |
| ATR too low or too high | Yes | Block entry |

---

## IDEA 5 — TP, SL, Trailing Stop & Lot Sizing

### Purpose
Define exactly how trades are sized, where SL and TP are placed, how the trailing stop moves, and how lot sizes grow with the account.

### Spread Check at Entry
- Final spread check before every order is sent: **35 points maximum**
- If spread exceeds 35 at execution moment → do not send the order

### Stop Loss (SL)
- SL is ATR-based: `SL = ATR(14) × 1.5`
- SL is placed below (buy) or above (sell) the Order Block or FVG from Idea 2
- Never placed inside an Order Block or FVG
- Minimum SL on M1–M5 entries: **20–40 pips**
- Minimum SL on M15 entries: **40–80 pips**
- SL is set at trade open and never loosened

### Take Profit (TP)
- TP is set at the nearest Idea 1 key level (Daily high/low, 1H 0.68, 15M 0.68)
- If no Idea 1 level is within range: TP defaults to `ATR(14) × 3` from entry
- Maximum TP target: up to **1,500 pips** on strong trending moves

### Breakeven Rule
- When trade profit reaches `ATR(14) × 1.0` from entry → SL moves to breakeven (entry price)
- SL never moves back after breakeven is set

### Partial Close Rule
- When price hits the first Idea 1 key level → close **50% of the position**
- Remaining 50% continues running with trailing stop toward full TP target

### Trailing Stop — ATR Based
- Formula: `Trailing Distance = max(MinTrailPoints, ATR(14) × 1.0)`
- Trailing only starts when trade profit reaches `ATR(14) × 0.5`
- SL moves forward only — never loosens, never moves back
- SL updates in steps — only moves when new SL differs from current SL by at least `ATR(14) × 0.5`
- Runs on every tick

### Dynamic Lot Sizing — Compounding
- Starting balance: **$14**
- Lot formula: `Lot = (Balance × RiskPercent) ÷ (SL_pips × PipValue)`
- Lot size recalculated on every new trade based on current balance
- Lot size grows automatically as balance grows

### Lot Size Risk Cap by Balance Stage

| Balance Range | Max Risk Per Trade |
|---|---|
| $14 – $100 | Max $5 loss per trade |
| $100 – $500 | Max 30% of balance |
| $500 – $2,000 | Max 20% of balance |
| $2,000 – $10,000 | Max 15% of balance |
| $10,000 – $40,000 | Max 10% of balance |

### Consecutive Loss Pause
- 2 losses in a row → pause trading for rest of that day
- 3 losses in a row across 2 days → pause trading for full 24 hours
- After pause: lot size resets to current balance calculation — no revenge sizing

### Drawdown Soft Cap
- Balance drops 10% from its all-time high → risk per trade drops to half automatically
- Balance drops 20% from its all-time high → EA stops all trading until manually reset

### Near-Target Lock
- When balance reaches **$35,000** → max risk per trade drops to 5%
- TP targets remain the same — only lot size risk reduces
- Protects the final stretch from being blown before reaching $40,000

---

## IDEA 6 — Entry Logic (Full Trade Trigger)

### Purpose
Define exactly when and how the EA opens a trade. Every step must pass before an order is sent.

### Entry Flow

```
Step 1: Idea 4 Protection Check
        ↓ Pass
Step 2: Idea 3 Indicator Filter Check
        ↓ Pass
Step 3: Price Near Idea 1 Key Level
        ↓ Pass
Step 4: Idea 2 Smart Money Confirmation at That Level
        ↓ Pass
Step 5: Determine Direction (BUY or SELL)
        ↓ Confirmed
Step 6: Execute Trade with Idea 5 Sizing and Levels
```

### Step 1 — Protection Check (Idea 4)
All must be true:
- Not inside news window
- Spread below 35 points
- ATR not too low or too high
- Daily loss limit not yet hit
- Inside allowed session hours
- Max trades per day not yet reached

### Step 2 — Indicator Filter (Idea 3)
All must be true:
- ADX above 25
- ADX direction confirmed (+DI or −DI leading)
- RSI and Stoch agree on direction
- If ADX above 37 and still rising → **wait, do not enter**
- If ADX peaked 37–40 and now falling + RSI/Stoch at extreme → **proceed to Step 3**

### Step 3 — Price Near Idea 1 Level
- Price must be touching or within `ATR × 0.5` of at least one:
  - Orange Daily high or low line
  - White/Green 1H 0.68 level
  - Blue 15M 0.68 trendline
- If price is not near any Idea 1 line → **skip, no entry**

### Step 4 — Idea 2 Confirmation at That Level
At least one of these must be present at the same level:
- Order Block present at that level
- FVG box present at that level
- BIAS line confirms direction
- Component B dot (RSI + Stoch agree) shows on current candle
- Component C arrow (candle pattern) shows at that level

### Step 5 — Direction Decision

| All Conditions | Direction |
|---|---|
| Price touches support level + ADX +DI leading + RSI below 30 + Stoch below 20 + Bullish OB or FVG present | **BUY** |
| Price touches resistance level + ADX −DI leading + RSI above 70 + Stoch above 80 + Bearish OB or FVG present | **SELL** |

### Step 6 — Trade Execution
- Calculate lot size: `Balance × RiskPercent ÷ (SL_pips × PipValue)`
- Apply balance stage risk cap from Idea 5
- Set SL: `ATR(14) × 1.5` below entry (buy) or above entry (sell)
- Set TP: nearest Idea 1 level or `ATR(14) × 3` minimum
- Final spread check before sending order
- Send order

---

## Growth Plan — $14 to $40,000

### Target
- Starting balance: **$14**
- Target balance: **$40,000**
- Estimated timeline: **80–100 trading days**
- Trades per week: **3–4 quality trades only**

### Milestone Timeline (55% Win Rate Estimate)

| Milestone | Estimated Day | Estimated Week |
|---|---|---|
| $14 → $100 | Day ~16 | Week 4 |
| $100 → $500 | Day ~69 | Week 14 |
| $500 → $1,000 | Day ~71 | Week 15 |
| $1,000 → $10,000 | Day ~77 | Week 16 |
| $10,000 → $40,000 | Day ~81 | Week 17 |

### Key Notes
- The hardest phase is $14 → $500 — slow growth due to tiny lot sizes and $5 daily cap
- After $500 compounding accelerates rapidly
- The $1,000 → $40,000 jump happens in approximately 1–2 weeks — the most dangerous phase
- Near-Target Lock at $35,000 is critical to protect the final stretch
- Higher win rate (60–65%) can hit target in 60–70 days
- Lower win rate (45–50%) extends timeline to 120–150 days

---

## MQL5 Developer Notes

### Indicator Inputs (Configurable)
- RSI Period: 14
- Stochastic K: 14, D: 1, Slowing: 3
- ATR Period: 14
- ADX Period: 14
- Fib Extension Level: 0.68
- Daily Lookback: 4 bars (not strict)
- Max Spread: 35 points
- Max Slippage: 5 points
- News Block Before: 15 minutes
- News Block After: 15 minutes
- ATR Min Threshold: 5 points
- ATR Max Threshold: 150 points
- Trailing Multiplier: 1.0 × ATR
- SL Multiplier: 1.5 × ATR
- TP Multiplier: 3.0 × ATR (default)
- Breakeven Trigger: 1.0 × ATR
- Partial Close Level: First Idea 1 line hit
- Partial Close Size: 50%

### Refresh Logic
- Idea 1 lines → **OnCalculate new bar** (not every tick — level-based)
- Idea 2 components → **OnTick** (real-time Smart Money detection)
- Idea 3 indicators → **OnTick** (real-time filter)
- Idea 4 protection → **OnTick** (checked before every potential entry)
- Idea 5 trailing stop → **OnTick** (must track price continuously)
- Idea 6 entry → **OnTick** (all steps checked on every tick)

### Session Time Implementation
- Use broker server time (`TimeCurrent()`)
- Asian: 00:00–06:00, London: 08:00–12:00, New York: 13:00–17:00

### News Filter Implementation
- Use MQL5 built-in `CalendarValueHistory()` from the Economic Calendar API
- Filter by currency: USD and XAU
- Filter by importance: CALENDAR_IMPORTANCE_HIGH only
- Check on timer + cache, then runtime check at entry signal

### Multi-Timeframe Line Drawing
- Use `ChartIndicatorAdd()` or draw objects using `ObjectCreate()` with `OBJ_HLINE` and `OBJ_TREND`
- Lines drawn as chart objects — visible across timeframes when object is created on the correct timeframe

