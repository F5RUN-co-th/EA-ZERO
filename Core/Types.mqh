//+------------------------------------------------------------------+
//| Types.mqh                                                         |
//| Core data types shared across the Pattern EA modules.             |
//+------------------------------------------------------------------+
#property strict

//+------------------------------------------------------------------+
//| Candlestick pattern classification                                |
//+------------------------------------------------------------------+
enum PatternType
{
   PATTERN_NONE,

   PATTERN_HAMMER,
   PATTERN_HANGING_MAN,

   PATTERN_INVERTED_HAMMER,
   PATTERN_SHOOTING_STAR,

   PATTERN_BULLISH_ENGULFING,
   PATTERN_BEARISH_ENGULFING,

   PATTERN_MORNING_STAR,
   PATTERN_EVENING_STAR,

   PATTERN_THREE_WHITE_SOLDIERS,
   PATTERN_THREE_BLACK_CROWS,

   PATTERN_DOJI,
   PATTERN_SPINNING_TOP,

   PATTERN_HARAMI_BULL,
   PATTERN_HARAMI_BEAR,

   PATTERN_PIERCING_LINE,
   PATTERN_DARK_CLOUD,

   PATTERN_TWEEZER_TOP,
   PATTERN_TWEEZER_BOTTOM,

   PATTERN_BULLISH_MARUBOZU,
   PATTERN_BEARISH_MARUBOZU
};

//+------------------------------------------------------------------+
//| Result of a single pattern detection.                             |
//+------------------------------------------------------------------+
struct PatternSignal
{
   PatternType type;         // Which pattern fired
   int         barShift;     // Bar index (shift) where the pattern was found
   double      bullishScore; // Raw bullish weight contributed by this signal
   double      bearishScore; // Raw bearish weight contributed by this signal
   double      neutralScore; // Raw neutral / indecision weight
   double      confidence;   // 0.0 - 1.0 confidence of the detection

   //--- Reset all fields to a clean default state
   void Clear()
   {
      type         = PATTERN_NONE;
      barShift     = 0;
      bullishScore = 0.0;
      bearishScore = 0.0;
      neutralScore = 0.0;
      confidence   = 0.0;
   }
};

//+------------------------------------------------------------------+
//| Trade direction decided by the Decision Engine.                   |
//+------------------------------------------------------------------+
enum TradeDirection
{
   DIRECTION_NONE,
   DIRECTION_BUY,
   DIRECTION_SELL
};

//+------------------------------------------------------------------+
//| System state used by Strategy/StateMachine.mqh.                   |
//|                                                                    |
//| STATE_FLAT     : no position, free to evaluate new signals        |
//| STATE_IN_TRADE : a position is currently open                     |
//| STATE_COOLDOWN : hard block - no new trades until N bars pass     |
//| STATE_RECOVERY : trading allowed, but RiskManager reduces size    |
//+------------------------------------------------------------------+
enum SystemState
{
   STATE_FLAT,
   STATE_IN_TRADE,
   STATE_COOLDOWN,
   STATE_RECOVERY
};
//+------------------------------------------------------------------+
