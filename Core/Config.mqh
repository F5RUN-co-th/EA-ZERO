//+------------------------------------------------------------------+
//| Config.mqh                                                        |
//| All tunable parameters live here so they can be optimized in the  |
//| Strategy Tester. No magic numbers/thresholds elsewhere - anything |
//| a pattern/filter/risk rule needs should be an input added here.   |
//+------------------------------------------------------------------+
#property strict

input group "=== General ==="
input int  InpConfigVersion   = 1;         // Config/strategy version - traced via Magic Number + trade comments
input long InpBaseMagicNumber = 20260700;  // Base magic number (version is appended, see GetMagicNumber())

input group "=== Risk ==="
input double InpRiskPercent           = 1.0;  // % of equity risked per trade (used if InpFixedLot == 0)
input double InpFixedLot              = 0.0;  // Fixed lot size, 0 = use InpRiskPercent instead
input double InpStopLossATRMultiplier = 1.5;  // SL distance = ATR * this multiplier
input double InpTakeProfitRR          = 2.0;  // TP distance = SL distance * this R:R ratio
input int    InpCooldownBars          = 3;    // Bars to stay in COOLDOWN state after a closed trade

input group "=== Execution Filter ==="
input double InpMaxSpreadPoints  = 30;    // Reject new trades if spread exceeds this (points)
input bool   InpUseSessionFilter = true;  // Enable/disable the session time filter
input int    InpSessionStartHour = 7;     // Session filter start hour (broker time)
input int    InpSessionEndHour   = 21;    // Session filter end hour (broker time)

input group "=== Trade Lock ==="
input bool InpOneTradePerBar   = true; // Prevent opening more than one trade per bar
input int  InpMaxOpenPositions = 1;    // Max concurrent open positions for this EA/symbol

input group "=== Emergency ==="
input bool InpEnableEmergencyStop = true; // Master kill-switch check, evaluated every tick

//+------------------------------------------------------------------+
//| Combines base magic number with config version so trade history / |
//| backtest reports can always be traced back to a parameter set.    |
//| e.g. version 1 -> 20260800, version 2 -> 20260900, etc.            |
//+------------------------------------------------------------------+
long GetMagicNumber()
{
   return InpBaseMagicNumber + (InpConfigVersion * 100);
}
//+------------------------------------------------------------------+
