//+------------------------------------------------------------------+
//| Config.mqh                                                        |
//| All tunable parameters live here so they can be optimized in the  |
//| Strategy Tester. No magic numbers/thresholds elsewhere - anything |
//| a pattern/filter/risk rule needs should be an input added here.   |
//+------------------------------------------------------------------+
#property strict

#include "Types.mqh"

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

input group "=== Decision Engine ==="
input double InpMinScoreThreshold = 1.0; // A direction's score must reach at least this to ever qualify
input double InpDominanceRatio    = 1.2; // A direction must beat the opposite score by this ratio to win (avoids close calls)

input group "=== Emergency ==="
input bool InpEnableEmergencyStop = true; // Master kill-switch check, evaluated every tick

input group "=== Market Data ==="
input int InpATRPeriod = 14; // ATR period used for normalizing pattern thresholds and SL distance

input group "=== Pattern Thresholds ==="
input double InpDojiMaxBodyRatio             = 0.1;  // body/range <= this => Doji
input double InpMarubozuMinBodyRatio         = 0.9;  // body/range >= this => Marubozu
input double InpHammerMinShadowRatio         = 2.0;  // long shadow must be >= body * this, for Hammer/Shooting Star
input double InpHammerMaxOppositeShadowRatio = 0.25; // opposite shadow must be <= body * this, for Hammer/Shooting Star
input double InpTweezerTolerance             = 0.1;  // max high/low difference, as a fraction of avg candle range
input double InpStarMaxBodyRatio             = 0.5;  // middle "star" body must be <= this fraction of either outer candle's body
input double InpSoldiersMaxShadowRatio       = 0.3;  // max shadow (in the trend direction) as a fraction of body, for Soldiers/Crows

input group "=== Pattern Weights (used by Classification/PatternClassifier.mqh) ==="
input double InpWeightHammer             = 1.0;
input double InpWeightShootingStar       = 1.0;
input double InpWeightDoji               = 0.5;
input double InpWeightSpinningTop        = 0.5;
input double InpWeightBullishMarubozu    = 1.0;
input double InpWeightBearishMarubozu    = 1.0;
input double InpWeightBullishEngulfing   = 1.5;
input double InpWeightBearishEngulfing   = 1.5;
input double InpWeightHaramiBull         = 1.0;
input double InpWeightHaramiBear         = 1.0;
input double InpWeightPiercingLine       = 1.5;
input double InpWeightDarkCloud          = 1.5;
input double InpWeightTweezerTop         = 1.0;
input double InpWeightTweezerBottom      = 1.0;
input double InpWeightMorningStar        = 2.0;
input double InpWeightEveningStar        = 2.0;
input double InpWeightThreeWhiteSoldiers = 2.0;
input double InpWeightThreeBlackCrows    = 2.0;

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
