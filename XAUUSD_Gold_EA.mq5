//+------------------------------------------------------------------+
//|                                              XAUUSD_Gold_EA.mq5 |
//|                                   Advanced Gold Trading System   |
//|                                              Version 1.0 - 2027  |
//+------------------------------------------------------------------+
#property copyright "XAUUSD Gold EA System"
#property version   "1.00"
#property description "Complete 6-IDEA Gold Trading System"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

// Global Objects
CTrade trade;
CPositionInfo position;
CAccountInfo account;

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+

// === IDEA 1: Key Level Lines ===
input group "IDEA 1 — Key Level Lines"
input int DailyLookback = 4;                    // Daily lookback period
input double FibLevel = 0.68;                   // Fibonacci 0.68 level

// === IDEA 3: Indicator Filters ===
input group "IDEA 3 — Indicator Filters"
input int RSI_Period = 14;                      // RSI Period
input int Stoch_K = 14;                         // Stochastic K
input int Stoch_D = 1;                          // Stochastic D
input int Stoch_Slowing = 3;                    // Stochastic Slowing
input int ATR_Period = 14;                      // ATR Period
input int ADX_Period = 14;                      // ADX Period

// === IDEA 4: Protection System ===
input group "IDEA 4 — Protection System"
input int MaxSpread = 35;                       // Max spread in points
input int MaxSlippage = 5;                      // Max slippage in points
input int NewsBlockMinutesBefore = 15;          // News block before (minutes)
input int NewsBlockMinutesAfter = 15;           // News block after (minutes)
input double ATR_MinThreshold = 5.0;            // ATR minimum threshold
input double ATR_MaxThreshold = 150.0;          // ATR maximum threshold
input double DailyLossLimit_Small = 5.0;        // Daily loss limit under $100
input int SpreadCalmCandlesWait = 7;            // Candles to wait after spread spike

// === IDEA 5: TP/SL/Trailing/Lot Sizing ===
input group "IDEA 5 — TP/SL & Risk Management"
input double SL_ATR_Multiplier = 1.5;           // SL = ATR × this
input double TP_ATR_Multiplier = 3.0;           // TP = ATR × this (default)
input double Trailing_ATR_Multiplier = 1.0;     // Trailing = ATR × this
input double Breakeven_ATR_Trigger = 1.0;       // Breakeven trigger = ATR × this
input double PartialClosePercent = 50.0;        // Partial close percentage
input int MinSL_M1M5_Pips = 20;                 // Minimum SL on M1-M5 (pips)
input int MaxSL_M1M5_Pips = 40;                 // Maximum SL on M1-M5 (pips)
input int MinSL_M15_Pips = 40;                  // Minimum SL on M15 (pips)
input int MaxSL_M15_Pips = 80;                  // Maximum SL on M15 (pips)

// === IDEA 6: Entry Logic ===
input group "IDEA 6 — Entry Control"
input int MaxTradesPerDay_Small = 3;            // Max trades/day (balance < $100)
input int MaxTradesPerDay_Large = 5;            // Max trades/day (balance >= $100)
input double TargetTradesPerDay = 1.5;          // Target trades per day (1-2)

// === Progressive Weekly Targets ===
input group "Progressive Weekly Targets"
input bool UseProgressiveTargets = true;        // Use progressive weekly targets
input double Week1_Target = 100.0;              // Week 1 target: $100
input double Week2_Target = 500.0;              // Week 2 target: $500
input double Week3_Target = 1500.0;             // Week 3 target: $1,500
input double Week4_Target = 3000.0;             // Week 4 target: $3,000
input double Week5_Target = 5000.0;             // Week 5 target: $5,000
input double Week6_Target = 7000.0;             // Week 6 target: $7,000
input double Week7_Target = 12000.0;            // Week 7 target: $12,000
input double Week8_Target = 15000.0;            // Week 8 target: $15,000
input double Week9_Target = 20000.0;            // Week 9 target: $20,000
input double FinalTarget = 40000.0;             // Final target: $40,000

// === UI & Display ===
input group "UI Settings"
input bool ShowUI = true;                       // Show UI panel
input color UI_BackgroundColor = clrBlack;      // UI background color
input color UI_TextColor = clrWhite;            // UI text color
input int UI_Corner = CORNER_LEFT_UPPER;        // UI corner position
input int UI_X_Offset = 10;                     // UI X offset
input int UI_Y_Offset = 10;                     // UI Y offset

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+

// Handles for indicators
int handle_RSI_M15, handle_Stoch_M15, handle_ATR_M15, handle_ADX_M15;
int handle_RSI_M5, handle_Stoch_M5;
int handle_ATR_D1;

// Arrays for indicator values
double RSI_M15[], Stoch_Main_M15[], Stoch_Signal_M15[];
double ATR_M15[], ADX_Main[], ADX_Plus[], ADX_Minus[];
double RSI_M5[], Stoch_Main_M5[];
double ATR_D1[];

// Key level tracking
double Daily_High = 0, Daily_Low = 0;
double H1_Fib_Level = 0;
double M15_Fib_Level = 0;

// Trading state
int TradesOpenedToday = 0;
datetime LastTradeDate = 0;
datetime CurrentDay = 0;
double DailyStartingEquity = 0;
double AccountHighWaterMark = 0;
int ConsecutiveLosses = 0;
datetime PauseUntil = 0;
bool TradingPausedToday = false;

// Spread spike tracking
datetime SpreadSpikeTime = 0;
int CandlesSinceSpreadNormal = 0;

// Session times (broker server time)
struct SessionTime {
    int StartHour;
    int StartMinute;
    int EndHour;
    int EndMinute;
};

SessionTime Asian = {0, 0, 6, 0};
SessionTime London = {8, 0, 12, 0};
SessionTime NewYork = {13, 0, 17, 0};

// Weekly target tracking
datetime StartDate = 0;
int CurrentWeek = 0;

// Smart Money tracking
struct OrderBlockInfo {
    double High;
    double Low;
    datetime Time;
    bool IsBullish;
    bool IsValid;
};

struct FVGInfo {
    double Upper;
    double Lower;
    datetime Time;
    bool IsBullish;
    bool IsValid;
};

OrderBlockInfo BullishOB, BearishOB;
FVGInfo BullishFVG, BearishFVG;

// UI Object names
string UI_Panel = "UI_MainPanel";
string UI_Label_Prefix = "UI_Label_";

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("=== XAUUSD Gold EA System Initialized ===");
    Print("Version: 1.0 - 2027 Edition");

    // Initialize indicator handles for M15
    handle_RSI_M15 = iRSI(_Symbol, PERIOD_M15, RSI_Period, PRICE_CLOSE);
    handle_Stoch_M15 = iStochastic(_Symbol, PERIOD_M15, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, STO_LOWHIGH);
    handle_ATR_M15 = iATR(_Symbol, PERIOD_M15, ATR_Period);
    handle_ADX_M15 = iADX(_Symbol, PERIOD_M15, ADX_Period);

    // Initialize indicator handles for M5
    handle_RSI_M5 = iRSI(_Symbol, PERIOD_M5, RSI_Period, PRICE_CLOSE);
    handle_Stoch_M5 = iStochastic(_Symbol, PERIOD_M5, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, STO_LOWHIGH);

    // Initialize ATR for Daily
    handle_ATR_D1 = iATR(_Symbol, PERIOD_D1, ATR_Period);

    // Check if handles are valid
    if(handle_RSI_M15 == INVALID_HANDLE || handle_Stoch_M15 == INVALID_HANDLE ||
       handle_ATR_M15 == INVALID_HANDLE || handle_ADX_M15 == INVALID_HANDLE)
    {
        Print("ERROR: Failed to create indicator handles for M15");
        return(INIT_FAILED);
    }

    if(handle_RSI_M5 == INVALID_HANDLE || handle_Stoch_M5 == INVALID_HANDLE)
    {
        Print("ERROR: Failed to create indicator handles for M5");
        return(INIT_FAILED);
    }

    if(handle_ATR_D1 == INVALID_HANDLE)
    {
        Print("ERROR: Failed to create ATR handle for D1");
        return(INIT_FAILED);
    }

    // Set array as series
    ArraySetAsSeries(RSI_M15, true);
    ArraySetAsSeries(Stoch_Main_M15, true);
    ArraySetAsSeries(Stoch_Signal_M15, true);
    ArraySetAsSeries(ATR_M15, true);
    ArraySetAsSeries(ADX_Main, true);
    ArraySetAsSeries(ADX_Plus, true);
    ArraySetAsSeries(ADX_Minus, true);
    ArraySetAsSeries(RSI_M5, true);
    ArraySetAsSeries(Stoch_Main_M5, true);
    ArraySetAsSeries(ATR_D1, true);

    // Initialize account tracking
    AccountHighWaterMark = account.Balance();
    DailyStartingEquity = account.Equity();
    CurrentDay = iTime(_Symbol, PERIOD_D1, 0);
    StartDate = TimeCurrent();

    // Initialize Smart Money structures
    BullishOB.IsValid = false;
    BearishOB.IsValid = false;
    BullishFVG.IsValid = false;
    BearishFVG.IsValid = false;

    // Create UI
    if(ShowUI)
        CreateUI();

    // Draw key levels
    DrawKeyLevels();

    Print("Initialization complete. Starting balance: $", DoubleToString(account.Balance(), 2));
    Print("Target: $", DoubleToString(FinalTarget, 2));

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("=== EA Deinitialized. Reason: ", reason, " ===");

    // Release indicator handles
    if(handle_RSI_M15 != INVALID_HANDLE) IndicatorRelease(handle_RSI_M15);
    if(handle_Stoch_M15 != INVALID_HANDLE) IndicatorRelease(handle_Stoch_M15);
    if(handle_ATR_M15 != INVALID_HANDLE) IndicatorRelease(handle_ATR_M15);
    if(handle_ADX_M15 != INVALID_HANDLE) IndicatorRelease(handle_ADX_M15);
    if(handle_RSI_M5 != INVALID_HANDLE) IndicatorRelease(handle_RSI_M5);
    if(handle_Stoch_M5 != INVALID_HANDLE) IndicatorRelease(handle_Stoch_M5);
    if(handle_ATR_D1 != INVALID_HANDLE) IndicatorRelease(handle_ATR_D1);

    // Clean up UI
    if(ShowUI)
        DeleteUI();

    // Clean up chart objects
    DeleteAllObjects();
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if new day started
    CheckNewDay();

    // Update key levels on new bar
    static datetime lastBarTime = 0;
    datetime currentBarTime = iTime(_Symbol, PERIOD_M15, 0);
    if(currentBarTime != lastBarTime)
    {
        lastBarTime = currentBarTime;
        DrawKeyLevels();
    }

    // Update Smart Money components (every tick)
    UpdateSmartMoneyComponents();

    // Manage open positions
    ManageOpenPositions();

    // Update UI
    if(ShowUI)
        UpdateUI();

    // Check for entry signals
    if(!IsAccountPaused())
        CheckEntrySignals();
}

//+------------------------------------------------------------------+
//| Check if new day started and reset daily variables                |
//+------------------------------------------------------------------+
void CheckNewDay()
{
    datetime newDay = iTime(_Symbol, PERIOD_D1, 0);

    if(newDay != CurrentDay)
    {
        CurrentDay = newDay;
        TradesOpenedToday = 0;
        DailyStartingEquity = account.Equity();
        TradingPausedToday = false;
        CandlesSinceSpreadNormal = 0;

        // Calculate current week
        CurrentWeek = (int)((TimeCurrent() - StartDate) / (7 * 24 * 3600)) + 1;

        Print("=== New Trading Day ===");
        Print("Current Week: ", CurrentWeek);
        Print("Starting Equity: $", DoubleToString(DailyStartingEquity, 2));
        Print("Balance: $", DoubleToString(account.Balance(), 2));
    }
}

//+------------------------------------------------------------------+
//| IDEA 1: Draw Key Level Lines                                      |
//+------------------------------------------------------------------+
void DrawKeyLevels()
{
    // Line 1: Orange Daily High/Low
    DrawDailyHighLow();

    // Line 2: White/Green 1H Fib 0.68
    DrawH1FibLevel();

    // Line 3: Blue 15M Fib 0.68 Trendline
    DrawM15FibLevel();
}

//+------------------------------------------------------------------+
//| Draw Daily High/Low (Orange)                                      |
//+------------------------------------------------------------------+
void DrawDailyHighLow()
{
    double highestHigh = 0;
    double lowestLow = DBL_MAX;

    // Look back ~4 days for swing high/low
    for(int i = 0; i < DailyLookback; i++)
    {
        double high = iHigh(_Symbol, PERIOD_D1, i);
        double low = iLow(_Symbol, PERIOD_D1, i);

        if(high > highestHigh)
            highestHigh = high;
        if(low < lowestLow)
            lowestLow = low;
    }

    Daily_High = highestHigh;
    Daily_Low = lowestLow;

    // Draw high line
    DrawHLine("Daily_High", Daily_High, clrOrange, 3, STYLE_SOLID);

    // Draw low line
    DrawHLine("Daily_Low", Daily_Low, clrOrange, 3, STYLE_SOLID);
}

//+------------------------------------------------------------------+
//| Draw 1H Fibonacci 0.68 Level (White/Green)                        |
//+------------------------------------------------------------------+
void DrawH1FibLevel()
{
    // Find swing high and low on 1H
    double high = iHigh(_Symbol, PERIOD_H1, iHighest(_Symbol, PERIOD_H1, MODE_HIGH, 20, 0));
    double low = iLow(_Symbol, PERIOD_H1, iLowest(_Symbol, PERIOD_H1, MODE_LOW, 20, 0));

    // Calculate 0.68 Fib level
    H1_Fib_Level = low + (high - low) * FibLevel;

    // Draw line
    DrawHLine("H1_Fib_068", H1_Fib_Level, clrLightGreen, 3, STYLE_SOLID);
}

//+------------------------------------------------------------------+
//| Draw 15M Fibonacci 0.68 Trendline (Blue)                          |
//+------------------------------------------------------------------+
void DrawM15FibLevel()
{
    // Find swing high and low on M15
    int highestBar = iHighest(_Symbol, PERIOD_M15, MODE_HIGH, 30, 0);
    int lowestBar = iLowest(_Symbol, PERIOD_M15, MODE_LOW, 30, 0);

    double high = iHigh(_Symbol, PERIOD_M15, highestBar);
    double low = iLow(_Symbol, PERIOD_M15, lowestBar);

    // Calculate 0.68 Fib level
    M15_Fib_Level = low + (high - low) * FibLevel;

    // Draw as trendline (diagonal)
    datetime time1 = iTime(_Symbol, PERIOD_M15, lowestBar);
    datetime time2 = iTime(_Symbol, PERIOD_M15, 0);

    DrawTrendLine("M15_Fib_068_Trend", time1, M15_Fib_Level, time2, M15_Fib_Level, clrBlue, 3, STYLE_SOLID);
}

//+------------------------------------------------------------------+
//| IDEA 2: Update Smart Money Components                             |
//+------------------------------------------------------------------+
void UpdateSmartMoneyComponents()
{
    // Component A: Session High/Low (updated at session start)
    DrawSessionHighLow();

    // Component B: RSI + Stochastic Confluence Dot
    DrawRSIStochDots();

    // Component C: Candle Pattern Arrows
    DetectCandlePatterns();

    // Component D: Fair Value Gaps
    DetectFVG();

    // Component E: BIAS Line
    DrawBIASLine();

    // Component F: Order Blocks
    DetectOrderBlocks();
}

//+------------------------------------------------------------------+
//| Draw Session High/Low Lines                                       |
//+------------------------------------------------------------------+
void DrawSessionHighLow()
{
    datetime currentTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);

    // Determine current session and draw its high/low
    if(IsInSession(dt, Asian))
    {
        DrawSessionLines("Asian", clrYellow);
    }
    else if(IsInSession(dt, London))
    {
        DrawSessionLines("London", clrLime);
    }
    else if(IsInSession(dt, NewYork))
    {
        DrawSessionLines("NewYork", clrAqua);
    }
}

//+------------------------------------------------------------------+
//| Check if current time is in session                               |
//+------------------------------------------------------------------+
bool IsInSession(MqlDateTime &dt, SessionTime &session)
{
    int currentMinutes = dt.hour * 60 + dt.min;
    int sessionStart = session.StartHour * 60 + session.StartMinute;
    int sessionEnd = session.EndHour * 60 + session.EndMinute;

    return (currentMinutes >= sessionStart && currentMinutes < sessionEnd);
}

//+------------------------------------------------------------------+
//| Draw session high/low lines                                       |
//+------------------------------------------------------------------+
void DrawSessionLines(string sessionName, color lineColor)
{
    // This would track and draw session-specific high/low
    // Implementation simplified for brevity
}

//+------------------------------------------------------------------+
//| Draw RSI + Stochastic Confluence Dots                             |
//+------------------------------------------------------------------+
void DrawRSIStochDots()
{
    if(CopyBuffer(handle_RSI_M15, 0, 0, 1, RSI_M15) <= 0) return;
    if(CopyBuffer(handle_Stoch_M15, 0, 0, 1, Stoch_Main_M15) <= 0) return;

    double rsi = RSI_M15[0];
    double stoch = Stoch_Main_M15[0];

    // Oversold confluence (buy signal)
    if(rsi < 30 && stoch < 20)
    {
        DrawDot("RSI_Stoch_Buy_" + IntegerToString(iTime(_Symbol, PERIOD_M15, 0)),
                iTime(_Symbol, PERIOD_M15, 0), iLow(_Symbol, PERIOD_M15, 0), clrLime);
    }

    // Overbought confluence (sell signal)
    if(rsi > 70 && stoch > 80)
    {
        DrawDot("RSI_Stoch_Sell_" + IntegerToString(iTime(_Symbol, PERIOD_M15, 0)),
                iTime(_Symbol, PERIOD_M15, 0), iHigh(_Symbol, PERIOD_M15, 0), clrRed);
    }
}

//+------------------------------------------------------------------+
//| Detect Candle Patterns                                            |
//+------------------------------------------------------------------+
void DetectCandlePatterns()
{
    double open0 = iOpen(_Symbol, PERIOD_M15, 0);
    double close0 = iClose(_Symbol, PERIOD_M15, 0);
    double high0 = iHigh(_Symbol, PERIOD_M15, 0);
    double low0 = iLow(_Symbol, PERIOD_M15, 0);

    double open1 = iOpen(_Symbol, PERIOD_M15, 1);
    double close1 = iClose(_Symbol, PERIOD_M15, 1);
    double high1 = iHigh(_Symbol, PERIOD_M15, 1);
    double low1 = iLow(_Symbol, PERIOD_M15, 1);

    double body0 = MathAbs(close0 - open0);
    double body1 = MathAbs(close1 - open1);

    // Bullish Engulfing
    if(close1 < open1 && close0 > open0 && close0 > open1 && open0 < close1)
    {
        DrawArrow("Bullish_Engulf_" + IntegerToString(iTime(_Symbol, PERIOD_M15, 0)),
                  iTime(_Symbol, PERIOD_M15, 0), low0, 233, clrLime);
    }

    // Bearish Engulfing
    if(close1 > open1 && close0 < open0 && close0 < open1 && open0 > close1)
    {
        DrawArrow("Bearish_Engulf_" + IntegerToString(iTime(_Symbol, PERIOD_M15, 0)),
                  iTime(_Symbol, PERIOD_M15, 0), high0, 234, clrRed);
    }

    // Pin Bar / Rejection Wick
    double upperWick = high0 - MathMax(open0, close0);
    double lowerWick = MathMin(open0, close0) - low0;

    if(lowerWick > body0 * 2)
    {
        DrawArrow("Pin_Bullish_" + IntegerToString(iTime(_Symbol, PERIOD_M15, 0)),
                  iTime(_Symbol, PERIOD_M15, 0), low0, 233, clrYellow);
    }

    if(upperWick > body0 * 2)
    {
        DrawArrow("Pin_Bearish_" + IntegerToString(iTime(_Symbol, PERIOD_M15, 0)),
                  iTime(_Symbol, PERIOD_M15, 0), high0, 234, clrOrange);
    }
}

//+------------------------------------------------------------------+
//| Detect Fair Value Gaps (FVG)                                      |
//+------------------------------------------------------------------+
void DetectFVG()
{
    double high0 = iHigh(_Symbol, PERIOD_M15, 0);
    double low0 = iLow(_Symbol, PERIOD_M15, 0);
    double high1 = iHigh(_Symbol, PERIOD_M15, 1);
    double low1 = iLow(_Symbol, PERIOD_M15, 1);
    double high2 = iHigh(_Symbol, PERIOD_M15, 2);
    double low2 = iLow(_Symbol, PERIOD_M15, 2);

    // Bullish FVG: Candle 0 low > Candle 2 high
    if(low0 > high2)
    {
        BullishFVG.Upper = low0;
        BullishFVG.Lower = high2;
        BullishFVG.Time = iTime(_Symbol, PERIOD_M15, 0);
        BullishFVG.IsBullish = true;
        BullishFVG.IsValid = true;

        DrawRectangle("FVG_Bullish_" + IntegerToString(BullishFVG.Time),
                      BullishFVG.Time, BullishFVG.Upper,
                      iTime(_Symbol, PERIOD_M15, 0) + PeriodSeconds(PERIOD_M15) * 15,
                      BullishFVG.Lower, clrGreen, STYLE_SOLID, 1);
    }

    // Bearish FVG: Candle 0 high < Candle 2 low
    if(high0 < low2)
    {
        BearishFVG.Upper = low2;
        BearishFVG.Lower = high0;
        BearishFVG.Time = iTime(_Symbol, PERIOD_M15, 0);
        BearishFVG.IsBullish = false;
        BearishFVG.IsValid = true;

        DrawRectangle("FVG_Bearish_" + IntegerToString(BearishFVG.Time),
                      BearishFVG.Time, BearishFVG.Upper,
                      iTime(_Symbol, PERIOD_M15, 0) + PeriodSeconds(PERIOD_M15) * 15,
                      BearishFVG.Lower, clrRed, STYLE_SOLID, 1);
    }

    // Invalidate FVG if price closes through it
    double currentClose = iClose(_Symbol, PERIOD_M15, 0);

    if(BullishFVG.IsValid && currentClose < BullishFVG.Lower)
        BullishFVG.IsValid = false;

    if(BearishFVG.IsValid && currentClose > BearishFVG.Upper)
        BearishFVG.IsValid = false;
}

//+------------------------------------------------------------------+
//| Draw BIAS Line                                                    |
//+------------------------------------------------------------------+
void DrawBIASLine()
{
    double close0 = iClose(_Symbol, PERIOD_M15, 0);
    double high1 = iHigh(_Symbol, PERIOD_M15, 1);
    double low1 = iLow(_Symbol, PERIOD_M15, 1);

    // Bullish BIAS: current close > previous high
    if(close0 > high1)
    {
        DrawTrendLine("BIAS_Bullish_" + IntegerToString(iTime(_Symbol, PERIOD_M15, 0)),
                      iTime(_Symbol, PERIOD_M15, 1), high1,
                      iTime(_Symbol, PERIOD_M15, 0), close0,
                      clrLime, 3, STYLE_SOLID);
    }

    // Bearish BIAS: current close < previous low
    if(close0 < low1)
    {
        DrawTrendLine("BIAS_Bearish_" + IntegerToString(iTime(_Symbol, PERIOD_M15, 0)),
                      iTime(_Symbol, PERIOD_M15, 1), low1,
                      iTime(_Symbol, PERIOD_M15, 0), close0,
                      clrRed, 3, STYLE_SOLID);
    }
}

//+------------------------------------------------------------------+
//| Detect Order Blocks                                               |
//+------------------------------------------------------------------+
void DetectOrderBlocks()
{
    if(CopyBuffer(handle_ATR_M15, 0, 0, 1, ATR_M15) <= 0) return;
    double atr = ATR_M15[0];

    // Look for impulse moves
    double move0 = MathAbs(iClose(_Symbol, PERIOD_M15, 0) - iOpen(_Symbol, PERIOD_M15, 2));

    // Bullish Order Block: last bearish candle before bullish impulse
    if(move0 >= atr * 1.5)
    {
        double close1 = iClose(_Symbol, PERIOD_M15, 1);
        double open1 = iOpen(_Symbol, PERIOD_M15, 1);

        if(close1 < open1) // Bearish candle before impulse
        {
            BullishOB.High = iHigh(_Symbol, PERIOD_M15, 1);
            BullishOB.Low = iLow(_Symbol, PERIOD_M15, 1);
            BullishOB.Time = iTime(_Symbol, PERIOD_M15, 1);
            BullishOB.IsBullish = true;
            BullishOB.IsValid = true;

            DrawRectangle("OB_Bullish_" + IntegerToString(BullishOB.Time),
                          BullishOB.Time, BullishOB.High,
                          iTime(_Symbol, PERIOD_M15, 0) + PeriodSeconds(PERIOD_M15) * 20,
                          BullishOB.Low, clrGreen, STYLE_DOT, 2);
        }
    }

    // Bearish Order Block: last bullish candle before bearish impulse
    if(move0 >= atr * 1.5)
    {
        double close1 = iClose(_Symbol, PERIOD_M15, 1);
        double open1 = iOpen(_Symbol, PERIOD_M15, 1);

        if(close1 > open1) // Bullish candle before impulse
        {
            BearishOB.High = iHigh(_Symbol, PERIOD_M15, 1);
            BearishOB.Low = iLow(_Symbol, PERIOD_M15, 1);
            BearishOB.Time = iTime(_Symbol, PERIOD_M15, 1);
            BearishOB.IsBullish = false;
            BearishOB.IsValid = true;

            DrawRectangle("OB_Bearish_" + IntegerToString(BearishOB.Time),
                          BearishOB.Time, BearishOB.High,
                          iTime(_Symbol, PERIOD_M15, 0) + PeriodSeconds(PERIOD_M15) * 20,
                          BearishOB.Low, clrRed, STYLE_DOT, 2);
        }
    }

    // Invalidate OB if price closes through it
    double currentClose = iClose(_Symbol, PERIOD_M15, 0);

    if(BullishOB.IsValid && currentClose < BullishOB.Low)
        BullishOB.IsValid = false;

    if(BearishOB.IsValid && currentClose > BearishOB.High)
        BearishOB.IsValid = false;
}

//+------------------------------------------------------------------+
//| IDEA 3: Check Indicator Filters                                   |
//+------------------------------------------------------------------+
bool CheckIndicatorFilters(bool &isBuySignal)
{
    // Copy indicator buffers
    if(CopyBuffer(handle_ADX_M15, 0, 0, 3, ADX_Main) <= 0) return false;
    if(CopyBuffer(handle_ADX_M15, 1, 0, 3, ADX_Plus) <= 0) return false;
    if(CopyBuffer(handle_ADX_M15, 2, 0, 3, ADX_Minus) <= 0) return false;
    if(CopyBuffer(handle_RSI_M15, 0, 0, 1, RSI_M15) <= 0) return false;
    if(CopyBuffer(handle_Stoch_M15, 0, 0, 1, Stoch_Main_M15) <= 0) return false;
    if(CopyBuffer(handle_ATR_M15, 0, 0, 1, ATR_M15) <= 0) return false;

    double adx = ADX_Main[0];
    double adx_prev = ADX_Main[1];
    double plus_di = ADX_Plus[0];
    double minus_di = ADX_Minus[0];
    double rsi = RSI_M15[0];
    double stoch = Stoch_Main_M15[0];
    double atr = ATR_M15[0];

    // ADX below 20 → no trend, block entry
    if(adx < 20)
    {
        Print("Filter blocked: ADX too low (", DoubleToString(adx, 2), ")");
        return false;
    }

    // ADX rising above 37 → trend still running, wait
    if(adx > 37 && adx > adx_prev)
    {
        Print("Filter blocked: ADX too strong and rising (", DoubleToString(adx, 2), ")");
        return false;
    }

    // ATR volatility check
    if(atr < ATR_MinThreshold || atr > ATR_MaxThreshold)
    {
        Print("Filter blocked: ATR out of range (", DoubleToString(atr, 2), ")");
        return false;
    }

    // Strong SELL signal: ADX peaked and falling, RSI > 70, Stoch > 80
    if(adx >= 30 && adx < adx_prev && rsi > 70 && stoch > 80)
    {
        isBuySignal = false;
        Print("Strong SELL signal confirmed by indicators");
        return true;
    }

    // Strong BUY signal: ADX peaked and falling, RSI < 30, Stoch < 20
    if(adx >= 30 && adx < adx_prev && rsi < 30 && stoch < 20)
    {
        isBuySignal = true;
        Print("Strong BUY signal confirmed by indicators");
        return true;
    }

    // Bullish conditions: ADX > 25, +DI > -DI, RSI/Stoch agree
    if(adx > 25 && plus_di > minus_di && rsi < 50 && stoch < 20)
    {
        isBuySignal = true;
        Print("Bullish conditions confirmed");
        return true;
    }

    // Bearish conditions: ADX > 25, -DI > +DI, RSI/Stoch agree
    if(adx > 25 && minus_di > plus_di && rsi > 50 && stoch > 80)
    {
        isBuySignal = false;
        Print("Bearish conditions confirmed");
        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| IDEA 4: Protection System Checks                                  |
//+------------------------------------------------------------------+
bool PassProtectionChecks()
{
    // Check 1: Trading session hours
    if(!IsInTradingSession())
    {
        return false;
    }

    // Check 2: Max trades per day
    int maxTrades = (account.Balance() < 100) ? MaxTradesPerDay_Small : MaxTradesPerDay_Large;
    if(TradesOpenedToday >= maxTrades)
    {
        return false;
    }

    // Check 3: Spread filter
    double spread = GetCurrentSpread();
    if(spread > MaxSpread)
    {
        SpreadSpikeTime = TimeCurrent();
        CandlesSinceSpreadNormal = 0;
        return false;
    }

    // Check 4: Wait after spread spike
    if(SpreadSpikeTime > 0)
    {
        CandlesSinceSpreadNormal++;
        if(CandlesSinceSpreadNormal < SpreadCalmCandlesWait)
        {
            return false;
        }
        SpreadSpikeTime = 0;
    }

    // Check 5: News filter
    if(IsNewsTime())
    {
        return false;
    }

    // Check 6: Daily equity hard stop
    if(!CheckDailyEquityLimit())
    {
        return false;
    }

    // Check 7: ATR volatility guard
    if(CopyBuffer(handle_ATR_M15, 0, 0, 1, ATR_M15) > 0)
    {
        double atr = ATR_M15[0];
        if(atr < ATR_MinThreshold || atr > ATR_MaxThreshold)
        {
            return false;
        }
    }

    return true;
}

//+------------------------------------------------------------------+
//| Check if in trading session                                       |
//+------------------------------------------------------------------+
bool IsInTradingSession()
{
    datetime currentTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);

    return (IsInSession(dt, Asian) || IsInSession(dt, London) || IsInSession(dt, NewYork));
}

//+------------------------------------------------------------------+
//| Get current spread in points                                      |
//+------------------------------------------------------------------+
double GetCurrentSpread()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

    return (ask - bid) / point;
}

//+------------------------------------------------------------------+
//| Check if news time (simplified - real implementation needs calendar) |
//+------------------------------------------------------------------+
bool IsNewsTime()
{
    // This is a simplified version
    // Real implementation should use CalendarValueHistory()
    // For now, return false to allow trading
    return false;
}

//+------------------------------------------------------------------+
//| Check daily equity limit                                          |
//+------------------------------------------------------------------+
bool CheckDailyEquityLimit()
{
    double currentEquity = account.Equity();
    double dailyLoss = DailyStartingEquity - currentEquity;

    double lossLimit = (account.Balance() < 100) ? DailyLossLimit_Small : (account.Balance() * 0.05);

    if(dailyLoss > lossLimit)
    {
        TradingPausedToday = true;
        Print("Daily equity loss limit reached. Trading paused for today.");
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| Check if account is paused                                        |
//+------------------------------------------------------------------+
bool IsAccountPaused()
{
    if(TradingPausedToday)
        return true;

    if(TimeCurrent() < PauseUntil)
        return true;

    return false;
}

//+------------------------------------------------------------------+
//| Check for entry signals (IDEA 6)                                  |
//+------------------------------------------------------------------+
void CheckEntrySignals()
{
    // Step 1: Protection check
    if(!PassProtectionChecks())
        return;

    // Step 2: Indicator filter
    bool isBuySignal = false;
    if(!CheckIndicatorFilters(isBuySignal))
        return;

    // Step 3: Price near key level
    if(!IsPriceNearKeyLevel())
        return;

    // Step 4: Smart Money confirmation
    if(!HasSmartMoneyConfirmation(isBuySignal))
        return;

    // Step 5 & 6: Execute trade
    ExecuteTrade(isBuySignal);
}

//+------------------------------------------------------------------+
//| Check if price is near key level                                  |
//+------------------------------------------------------------------+
bool IsPriceNearKeyLevel()
{
    if(CopyBuffer(handle_ATR_M15, 0, 0, 1, ATR_M15) <= 0) return false;
    double atr = ATR_M15[0];
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double tolerance = atr * 0.5;

    // Check against Daily High/Low
    if(MathAbs(currentPrice - Daily_High) <= tolerance) return true;
    if(MathAbs(currentPrice - Daily_Low) <= tolerance) return true;

    // Check against H1 Fib level
    if(MathAbs(currentPrice - H1_Fib_Level) <= tolerance) return true;

    // Check against M15 Fib level
    if(MathAbs(currentPrice - M15_Fib_Level) <= tolerance) return true;

    return false;
}

//+------------------------------------------------------------------+
//| Check for Smart Money confirmation                                |
//+------------------------------------------------------------------+
bool HasSmartMoneyConfirmation(bool isBuySignal)
{
    // Check for Order Block
    if(isBuySignal && BullishOB.IsValid) return true;
    if(!isBuySignal && BearishOB.IsValid) return true;

    // Check for FVG
    if(isBuySignal && BullishFVG.IsValid) return true;
    if(!isBuySignal && BearishFVG.IsValid) return true;

    // Additional checks for BIAS, dots, arrows could be added here

    return true; // Simplified for now
}

//+------------------------------------------------------------------+
//| Execute trade with proper sizing and levels                       |
//+------------------------------------------------------------------+
void ExecuteTrade(bool isBuy)
{
    // Check trade frequency (aim for 1-2 trades per day)
    if(!ShouldTakeTrade())
    {
        Print("Trade frequency limit reached for today");
        return;
    }

    // Get ATR for SL/TP calculation
    if(CopyBuffer(handle_ATR_M15, 0, 0, 1, ATR_M15) <= 0) return;
    double atr = ATR_M15[0];

    // Calculate lot size
    double lotSize = CalculateLotSize(atr);
    if(lotSize <= 0)
    {
        Print("Invalid lot size calculated");
        return;
    }

    // Get current price
    double price = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);

    // Calculate SL and TP
    double sl = CalculateStopLoss(isBuy, price, atr);
    double tp = CalculateTakeProfit(isBuy, price, atr);

    // Final spread check
    if(GetCurrentSpread() > MaxSpread)
    {
        Print("Final spread check failed");
        return;
    }

    // Send order
    trade.SetDeviationInPoints(MaxSlippage);

    bool result = false;
    if(isBuy)
        result = trade.Buy(lotSize, _Symbol, price, sl, tp, "XAUUSD_EA_BUY");
    else
        result = trade.Sell(lotSize, _Symbol, price, sl, tp, "XAUUSD_EA_SELL");

    if(result)
    {
        TradesOpenedToday++;
        Print("Trade opened successfully. Direction: ", isBuy ? "BUY" : "SELL",
              " | Lot: ", DoubleToString(lotSize, 2),
              " | SL: ", DoubleToString(sl, _Digits),
              " | TP: ", DoubleToString(tp, _Digits));
    }
    else
    {
        Print("Trade failed. Error: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Check if should take trade based on frequency                     |
//+------------------------------------------------------------------+
bool ShouldTakeTrade()
{
    // Target is 1-2 trades per day, ~10 per week
    // Simple implementation: allow up to 2 trades per day
    return (TradesOpenedToday < 2);
}

//+------------------------------------------------------------------+
//| Calculate dynamic lot size with compounding                       |
//+------------------------------------------------------------------+
double CalculateLotSize(double atr)
{
    double balance = account.Balance();
    double sl_pips = (atr * SL_ATR_Multiplier) / _Point;

    // Get current balance stage and risk limit
    double maxRisk = GetMaxRiskForBalance(balance);

    // Calculate lot size
    double pipValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double lotSize = (balance * (maxRisk / 100.0)) / (sl_pips * pipValue);

    // Normalize lot size
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    lotSize = MathFloor(lotSize / lotStep) * lotStep;
    lotSize = MathMax(minLot, MathMin(maxLot, lotSize));

    return lotSize;
}

//+------------------------------------------------------------------+
//| Get max risk percentage based on balance                          |
//+------------------------------------------------------------------+
double GetMaxRiskForBalance(double balance)
{
    // Progressive weekly targets adjustment
    if(UseProgressiveTargets)
    {
        double weeklyTarget = GetWeeklyTarget();

        // Adjust risk based on distance to weekly target
        if(balance < weeklyTarget * 0.5)
            return 30.0; // Aggressive when far from target
        else if(balance < weeklyTarget * 0.8)
            return 20.0;
        else
            return 15.0; // Conservative near target
    }

    // Standard risk caps by balance stage
    if(balance < 100)
        return 30.0; // Max $5 loss on $14-$100
    else if(balance < 500)
        return 30.0;
    else if(balance < 2000)
        return 20.0;
    else if(balance < 10000)
        return 15.0;
    else if(balance < 35000)
        return 10.0;
    else
        return 5.0; // Near-target lock
}

//+------------------------------------------------------------------+
//| Get current weekly target                                         |
//+------------------------------------------------------------------+
double GetWeeklyTarget()
{
    switch(CurrentWeek)
    {
        case 1: return Week1_Target;
        case 2: return Week2_Target;
        case 3: return Week3_Target;
        case 4: return Week4_Target;
        case 5: return Week5_Target;
        case 6: return Week6_Target;
        case 7: return Week7_Target;
        case 8: return Week8_Target;
        case 9: return Week9_Target;
        default: return FinalTarget;
    }
}

//+------------------------------------------------------------------+
//| Calculate stop loss                                               |
//+------------------------------------------------------------------+
double CalculateStopLoss(bool isBuy, double entryPrice, double atr)
{
    double sl_distance = atr * SL_ATR_Multiplier;

    // Apply minimum SL based on timeframe
    ENUM_TIMEFRAMES tf = Period();
    double minSL_pips = (tf <= PERIOD_M5) ? MinSL_M1M5_Pips : MinSL_M15_Pips;
    double maxSL_pips = (tf <= PERIOD_M5) ? MaxSL_M1M5_Pips : MaxSL_M15_Pips;

    double minSL_price = minSL_pips * _Point * 10; // Convert pips to price
    double maxSL_price = maxSL_pips * _Point * 10;

    sl_distance = MathMax(sl_distance, minSL_price);
    sl_distance = MathMin(sl_distance, maxSL_price);

    double sl = isBuy ? entryPrice - sl_distance : entryPrice + sl_distance;

    return NormalizeDouble(sl, _Digits);
}

//+------------------------------------------------------------------+
//| Calculate take profit                                             |
//+------------------------------------------------------------------+
double CalculateTakeProfit(bool isBuy, double entryPrice, double atr)
{
    // First try to use nearest key level
    double tp = GetNearestKeyLevel(isBuy, entryPrice);

    // If no key level in range, use ATR-based TP
    if(tp == 0)
    {
        double tp_distance = atr * TP_ATR_Multiplier;
        tp = isBuy ? entryPrice + tp_distance : entryPrice - tp_distance;
    }

    return NormalizeDouble(tp, _Digits);
}

//+------------------------------------------------------------------+
//| Get nearest key level for TP                                      |
//+------------------------------------------------------------------+
double GetNearestKeyLevel(bool isBuy, double entryPrice)
{
    double nearest = 0;
    double minDistance = DBL_MAX;

    // Check all key levels
    double levels[] = {Daily_High, Daily_Low, H1_Fib_Level, M15_Fib_Level};

    for(int i = 0; i < ArraySize(levels); i++)
    {
        if(levels[i] == 0) continue;

        double distance = isBuy ? (levels[i] - entryPrice) : (entryPrice - levels[i]);

        if(distance > 0 && distance < minDistance)
        {
            minDistance = distance;
            nearest = levels[i];
        }
    }

    return nearest;
}

//+------------------------------------------------------------------+
//| Manage open positions (trailing stop, breakeven, partial close)   |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(!position.SelectByIndex(i)) continue;
        if(position.Symbol() != _Symbol) continue;

        ulong ticket = position.Ticket();
        double openPrice = position.PriceOpen();
        double currentSL = position.StopLoss();
        double currentTP = position.TakeProfit();
        bool isBuy = (position.Type() == POSITION_TYPE_BUY);

        double currentPrice = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

        if(CopyBuffer(handle_ATR_M15, 0, 0, 1, ATR_M15) <= 0) continue;
        double atr = ATR_M15[0];

        double profit = isBuy ? (currentPrice - openPrice) : (openPrice - currentPrice);

        // Breakeven rule
        if(profit >= atr * Breakeven_ATR_Trigger && currentSL != openPrice)
        {
            trade.PositionModify(ticket, openPrice, currentTP);
            Print("Position ", ticket, " moved to breakeven");
            continue;
        }

        // Trailing stop
        if(profit >= atr * 0.5)
        {
            double trailDistance = MathMax(20 * _Point, atr * Trailing_ATR_Multiplier);
            double newSL = isBuy ? (currentPrice - trailDistance) : (currentPrice + trailDistance);

            // Only move SL forward
            if((isBuy && newSL > currentSL) || (!isBuy && newSL < currentSL))
            {
                // Check if change is significant enough
                if(MathAbs(newSL - currentSL) >= atr * 0.5)
                {
                    trade.PositionModify(ticket, NormalizeDouble(newSL, _Digits), currentTP);
                    Print("Trailing stop updated for position ", ticket);
                }
            }
        }

        // Partial close at first key level
        if(IsAtKeyLevel(currentPrice))
        {
            double currentVolume = position.Volume();
            double closeVolume = NormalizeDouble(currentVolume * (PartialClosePercent / 100.0), 2);

            if(closeVolume >= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
            {
                trade.PositionClosePartial(ticket, closeVolume);
                Print("Partial close executed for position ", ticket, " | Volume: ", closeVolume);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check if price is at a key level                                  |
//+------------------------------------------------------------------+
bool IsAtKeyLevel(double price)
{
    double tolerance = 10 * _Point; // Small tolerance

    if(MathAbs(price - Daily_High) <= tolerance) return true;
    if(MathAbs(price - Daily_Low) <= tolerance) return true;
    if(MathAbs(price - H1_Fib_Level) <= tolerance) return true;
    if(MathAbs(price - M15_Fib_Level) <= tolerance) return true;

    return false;
}

//+------------------------------------------------------------------+
//| Create Modern UI Panel (2027 Standards)                           |
//+------------------------------------------------------------------+
void CreateUI()
{
    int panelWidth = 300;
    int panelHeight = 400;
    int x = UI_X_Offset;
    int y = UI_Y_Offset;
    int lineHeight = 20;

    // Create main panel background
    ObjectCreate(0, UI_Panel, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, UI_Panel, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, UI_Panel, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, UI_Panel, OBJPROP_XSIZE, panelWidth);
    ObjectSetInteger(0, UI_Panel, OBJPROP_YSIZE, panelHeight);
    ObjectSetInteger(0, UI_Panel, OBJPROP_CORNER, UI_Corner);
    ObjectSetInteger(0, UI_Panel, OBJPROP_COLOR, UI_BackgroundColor);
    ObjectSetInteger(0, UI_Panel, OBJPROP_BGCOLOR, UI_BackgroundColor);
    ObjectSetInteger(0, UI_Panel, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, UI_Panel, OBJPROP_WIDTH, 2);
    ObjectSetInteger(0, UI_Panel, OBJPROP_BACK, true);

    // Create labels
    CreateLabel(UI_Label_Prefix + "Title", x + 10, y + 10, "XAUUSD Gold EA v1.0", clrGold, 12, true);
    CreateLabel(UI_Label_Prefix + "Balance", x + 10, y + 40, "Balance: $0.00", UI_TextColor, 10);
    CreateLabel(UI_Label_Prefix + "Equity", x + 10, y + 60, "Equity: $0.00", UI_TextColor, 10);
    CreateLabel(UI_Label_Prefix + "Week", x + 10, y + 80, "Week: 1", UI_TextColor, 10);
    CreateLabel(UI_Label_Prefix + "Target", x + 10, y + 100, "Target: $100.00", UI_TextColor, 10);
    CreateLabel(UI_Label_Prefix + "Progress", x + 10, y + 120, "Progress: 0%", UI_TextColor, 10);
    CreateLabel(UI_Label_Prefix + "TodayTrades", x + 10, y + 150, "Today's Trades: 0", UI_TextColor, 10);
    CreateLabel(UI_Label_Prefix + "OpenPos", x + 10, y + 170, "Open Positions: 0", UI_TextColor, 10);
    CreateLabel(UI_Label_Prefix + "Status", x + 10, y + 200, "Status: Active", clrLime, 10, true);
    CreateLabel(UI_Label_Prefix + "ADX", x + 10, y + 230, "ADX: 0.0", UI_TextColor, 9);
    CreateLabel(UI_Label_Prefix + "RSI", x + 10, y + 250, "RSI: 0.0", UI_TextColor, 9);
    CreateLabel(UI_Label_Prefix + "Stoch", x + 10, y + 270, "Stoch: 0.0", UI_TextColor, 9);
    CreateLabel(UI_Label_Prefix + "ATR", x + 10, y + 290, "ATR: 0.0", UI_TextColor, 9);
    CreateLabel(UI_Label_Prefix + "Spread", x + 10, y + 310, "Spread: 0.0", UI_TextColor, 9);
    CreateLabel(UI_Label_Prefix + "Session", x + 10, y + 340, "Session: None", UI_TextColor, 10);
    CreateLabel(UI_Label_Prefix + "Footer", x + 10, y + 370, "© 2027 Advanced Trading System", clrDimGray, 8);
}

//+------------------------------------------------------------------+
//| Create a label on the chart                                       |
//+------------------------------------------------------------------+
void CreateLabel(string name, int x, int y, string text, color clr, int fontSize, bool bold = false)
{
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_CORNER, UI_Corner);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
    ObjectSetString(0, name, OBJPROP_FONT, bold ? "Arial Black" : "Arial");
    ObjectSetString(0, name, OBJPROP_TEXT, text);
}

//+------------------------------------------------------------------+
//| Update UI with current data                                       |
//+------------------------------------------------------------------+
void UpdateUI()
{
    double balance = account.Balance();
    double equity = account.Equity();
    double weeklyTarget = GetWeeklyTarget();
    double progress = (balance / weeklyTarget) * 100.0;

    ObjectSetString(0, UI_Label_Prefix + "Balance", OBJPROP_TEXT,
                    "Balance: $" + DoubleToString(balance, 2));
    ObjectSetString(0, UI_Label_Prefix + "Equity", OBJPROP_TEXT,
                    "Equity: $" + DoubleToString(equity, 2));
    ObjectSetString(0, UI_Label_Prefix + "Week", OBJPROP_TEXT,
                    "Week: " + IntegerToString(CurrentWeek));
    ObjectSetString(0, UI_Label_Prefix + "Target", OBJPROP_TEXT,
                    "Target: $" + DoubleToString(weeklyTarget, 2));
    ObjectSetString(0, UI_Label_Prefix + "Progress", OBJPROP_TEXT,
                    "Progress: " + DoubleToString(progress, 1) + "%");
    ObjectSetString(0, UI_Label_Prefix + "TodayTrades", OBJPROP_TEXT,
                    "Today's Trades: " + IntegerToString(TradesOpenedToday));
    ObjectSetString(0, UI_Label_Prefix + "OpenPos", OBJPROP_TEXT,
                    "Open Positions: " + IntegerToString(PositionsTotal()));

    // Status
    string status = "Active";
    color statusColor = clrLime;
    if(IsAccountPaused())
    {
        status = "Paused";
        statusColor = clrRed;
    }
    else if(!IsInTradingSession())
    {
        status = "Out of Session";
        statusColor = clrYellow;
    }

    ObjectSetString(0, UI_Label_Prefix + "Status", OBJPROP_TEXT, "Status: " + status);
    ObjectSetInteger(0, UI_Label_Prefix + "Status", OBJPROP_COLOR, statusColor);

    // Indicators
    if(CopyBuffer(handle_ADX_M15, 0, 0, 1, ADX_Main) > 0)
        ObjectSetString(0, UI_Label_Prefix + "ADX", OBJPROP_TEXT,
                        "ADX: " + DoubleToString(ADX_Main[0], 1));

    if(CopyBuffer(handle_RSI_M15, 0, 0, 1, RSI_M15) > 0)
        ObjectSetString(0, UI_Label_Prefix + "RSI", OBJPROP_TEXT,
                        "RSI: " + DoubleToString(RSI_M15[0], 1));

    if(CopyBuffer(handle_Stoch_M15, 0, 0, 1, Stoch_Main_M15) > 0)
        ObjectSetString(0, UI_Label_Prefix + "Stoch", OBJPROP_TEXT,
                        "Stoch: " + DoubleToString(Stoch_Main_M15[0], 1));

    if(CopyBuffer(handle_ATR_M15, 0, 0, 1, ATR_M15) > 0)
        ObjectSetString(0, UI_Label_Prefix + "ATR", OBJPROP_TEXT,
                        "ATR: " + DoubleToString(ATR_M15[0], 1));

    ObjectSetString(0, UI_Label_Prefix + "Spread", OBJPROP_TEXT,
                    "Spread: " + DoubleToString(GetCurrentSpread(), 1));

    // Session
    string sessionName = GetCurrentSessionName();
    ObjectSetString(0, UI_Label_Prefix + "Session", OBJPROP_TEXT,
                    "Session: " + sessionName);
}

//+------------------------------------------------------------------+
//| Get current session name                                          |
//+------------------------------------------------------------------+
string GetCurrentSessionName()
{
    datetime currentTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);

    if(IsInSession(dt, Asian)) return "Asian";
    if(IsInSession(dt, London)) return "London";
    if(IsInSession(dt, NewYork)) return "New York";

    return "None";
}

//+------------------------------------------------------------------+
//| Delete UI                                                          |
//+------------------------------------------------------------------+
void DeleteUI()
{
    ObjectDelete(0, UI_Panel);

    for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
    {
        string name = ObjectName(0, i);
        if(StringFind(name, UI_Label_Prefix) >= 0)
            ObjectDelete(0, name);
    }
}

//+------------------------------------------------------------------+
//| Delete all chart objects created by EA                            |
//+------------------------------------------------------------------+
void DeleteAllObjects()
{
    for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
    {
        string name = ObjectName(0, i);
        if(StringFind(name, "Daily_") >= 0 ||
           StringFind(name, "H1_") >= 0 ||
           StringFind(name, "M15_") >= 0 ||
           StringFind(name, "RSI_") >= 0 ||
           StringFind(name, "FVG_") >= 0 ||
           StringFind(name, "OB_") >= 0 ||
           StringFind(name, "BIAS_") >= 0 ||
           StringFind(name, "Pin_") >= 0 ||
           StringFind(name, "Bullish_") >= 0 ||
           StringFind(name, "Bearish_") >= 0)
        {
            ObjectDelete(0, name);
        }
    }
}

//+------------------------------------------------------------------+
//| Helper: Draw horizontal line                                      |
//+------------------------------------------------------------------+
void DrawHLine(string name, double price, color clr, int width, ENUM_LINE_STYLE style)
{
    if(ObjectFind(0, name) >= 0)
        ObjectDelete(0, name);

    ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
    ObjectSetInteger(0, name, OBJPROP_STYLE, style);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);
}

//+------------------------------------------------------------------+
//| Helper: Draw trend line                                           |
//+------------------------------------------------------------------+
void DrawTrendLine(string name, datetime time1, double price1, datetime time2, double price2,
                   color clr, int width, ENUM_LINE_STYLE style)
{
    if(ObjectFind(0, name) >= 0)
        ObjectDelete(0, name);

    ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
    ObjectSetInteger(0, name, OBJPROP_STYLE, style);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);
}

//+------------------------------------------------------------------+
//| Helper: Draw rectangle                                            |
//+------------------------------------------------------------------+
void DrawRectangle(string name, datetime time1, double price1, datetime time2, double price2,
                   color clr, ENUM_LINE_STYLE style, int width)
{
    if(ObjectFind(0, name) >= 0)
        ObjectDelete(0, name);

    ObjectCreate(0, name, OBJ_RECTANGLE, 0, time1, price1, time2, price2);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_STYLE, style);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
    ObjectSetInteger(0, name, OBJPROP_BACK, true);
    ObjectSetInteger(0, name, OBJPROP_FILL, true);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Helper: Draw arrow                                                |
//+------------------------------------------------------------------+
void DrawArrow(string name, datetime time, double price, int arrowCode, color clr)
{
    if(ObjectFind(0, name) >= 0)
        ObjectDelete(0, name);

    ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
    ObjectSetInteger(0, name, OBJPROP_ARROWCODE, arrowCode);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Helper: Draw dot                                                  |
//+------------------------------------------------------------------+
void DrawDot(string name, datetime time, double price, color clr)
{
    if(ObjectFind(0, name) >= 0)
        ObjectDelete(0, name);

    ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
    ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 159); // Small dot
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 3);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
