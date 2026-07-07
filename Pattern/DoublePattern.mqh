//+------------------------------------------------------------------+
//| DoublePattern.mqh                                                  |
//| Detects two-candle patterns: Bullish Engulfing, Bearish Engulfing. |
//| Harami / Piercing Line / Dark Cloud / Tweezer are Batch 3 - kept   |
//| out of this batch so it stays a size that compiles and tests      |
//| cleanly before moving on.                                         |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Types.mqh"
#include "../Utils/CandleUtils.mqh"

class CDoublePattern
{
public:
   /// prev = older candle, curr = newer candle (the one that just closed).
   static bool DetectBullishEngulfing(const MqlRates &prev, const MqlRates &curr, PatternSignal &signal)
   {
      signal.Clear();

      if(!CCandleUtils::IsBearish(prev) || !CCandleUtils::IsBullish(curr))
         return false;

      bool engulfs = (curr.open <= prev.close) && (curr.close >= prev.open);
      if(!engulfs)
         return false;

      signal.type          = PATTERN_BULLISH_ENGULFING;
      signal.bullishScore  = 1.0;

      double prevBody = CCandleUtils::BodySize(prev);
      double currBody = CCandleUtils::BodySize(curr);
      signal.confidence = (prevBody > 0.0) ? MathMin(1.0, currBody / prevBody / 2.0) : 0.5;

      return true;
   }

   /// prev = older candle, curr = newer candle (the one that just closed).
   static bool DetectBearishEngulfing(const MqlRates &prev, const MqlRates &curr, PatternSignal &signal)
   {
      signal.Clear();

      if(!CCandleUtils::IsBullish(prev) || !CCandleUtils::IsBearish(curr))
         return false;

      bool engulfs = (curr.open >= prev.close) && (curr.close <= prev.open);
      if(!engulfs)
         return false;

      signal.type          = PATTERN_BEARISH_ENGULFING;
      signal.bearishScore  = 1.0;

      double prevBody = CCandleUtils::BodySize(prev);
      double currBody = CCandleUtils::BodySize(curr);
      signal.confidence = (prevBody > 0.0) ? MathMin(1.0, currBody / prevBody / 2.0) : 0.5;

      return true;
   }
};
//+------------------------------------------------------------------+
