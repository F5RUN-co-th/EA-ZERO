//+------------------------------------------------------------------+
//| DoublePattern.mqh                                                  |
//| Detects two-candle patterns: Bullish Engulfing, Bearish Engulfing. |
//| Harami / Piercing Line / Dark Cloud / Tweezer are Batch 3 - kept   |
//| out of this batch so it stays a size that compiles and tests      |
//| cleanly before moving on.                                         |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Types.mqh"
#include "../Core/Config.mqh"
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

   /// Bullish Harami: prev is a large bearish candle, curr is a small candle
   /// (either color) whose body is fully contained within prev's body.
   /// Opposite of Engulfing - signals weakening downward momentum.
   static bool DetectBullishHarami(const MqlRates &prev, const MqlRates &curr, PatternSignal &signal)
   {
      signal.Clear();

      if(!CCandleUtils::IsBearish(prev))
         return false;

      double prevBody = CCandleUtils::BodySize(prev);
      double currBody = CCandleUtils::BodySize(curr);
      if(prevBody <= 0.0 || currBody >= prevBody)
         return false;

      double prevHigh = MathMax(prev.open, prev.close);
      double prevLow  = MathMin(prev.open, prev.close);
      double currHigh = MathMax(curr.open, curr.close);
      double currLow  = MathMin(curr.open, curr.close);

      if(!(currHigh <= prevHigh && currLow >= prevLow))
         return false;

      signal.type          = PATTERN_HARAMI_BULL;
      signal.bullishScore  = 1.0;
      signal.confidence    = 1.0 - (currBody / prevBody);
      return true;
   }

   /// Bearish Harami: prev is a large bullish candle, curr is a small candle
   /// whose body is fully contained within prev's body.
   static bool DetectBearishHarami(const MqlRates &prev, const MqlRates &curr, PatternSignal &signal)
   {
      signal.Clear();

      if(!CCandleUtils::IsBullish(prev))
         return false;

      double prevBody = CCandleUtils::BodySize(prev);
      double currBody = CCandleUtils::BodySize(curr);
      if(prevBody <= 0.0 || currBody >= prevBody)
         return false;

      double prevHigh = MathMax(prev.open, prev.close);
      double prevLow  = MathMin(prev.open, prev.close);
      double currHigh = MathMax(curr.open, curr.close);
      double currLow  = MathMin(curr.open, curr.close);

      if(!(currHigh <= prevHigh && currLow >= prevLow))
         return false;

      signal.type          = PATTERN_HARAMI_BEAR;
      signal.bearishScore  = 1.0;
      signal.confidence    = 1.0 - (currBody / prevBody);
      return true;
   }

   /// Piercing Line: prev bearish, curr opens below prev's close (gap down),
   /// then closes back up past the midpoint of prev's body (but not past prev's open).
   static bool DetectPiercingLine(const MqlRates &prev, const MqlRates &curr, PatternSignal &signal)
   {
      signal.Clear();

      if(!CCandleUtils::IsBearish(prev) || !CCandleUtils::IsBullish(curr))
         return false;

      double prevMid = CCandleUtils::MidPoint(prev);
      bool opensBelowPrevClose      = curr.open < prev.close;
      bool closesAboveMidBelowOpen  = (curr.close > prevMid) && (curr.close < prev.open);

      if(!opensBelowPrevClose || !closesAboveMidBelowOpen)
         return false;

      double prevBody = prev.open - prev.close; // prev is bearish, so this is positive
      if(prevBody <= 0.0)
         return false;

      signal.type         = PATTERN_PIERCING_LINE;
      signal.bullishScore = 1.0;
      signal.confidence   = MathMin(1.0, (curr.close - prev.close) / prevBody);
      return true;
   }

   /// Dark Cloud Cover: mirror of Piercing Line. prev bullish, curr opens
   /// above prev's close (gap up), then closes back down past the midpoint
   /// of prev's body (but not past prev's open).
   static bool DetectDarkCloudCover(const MqlRates &prev, const MqlRates &curr, PatternSignal &signal)
   {
      signal.Clear();

      if(!CCandleUtils::IsBullish(prev) || !CCandleUtils::IsBearish(curr))
         return false;

      double prevMid = CCandleUtils::MidPoint(prev);
      bool opensAbovePrevClose      = curr.open > prev.close;
      bool closesBelowMidAboveOpen  = (curr.close < prevMid) && (curr.close > prev.open);

      if(!opensAbovePrevClose || !closesBelowMidAboveOpen)
         return false;

      double prevBody = prev.close - prev.open; // prev is bullish, so this is positive
      if(prevBody <= 0.0)
         return false;

      signal.type         = PATTERN_DARK_CLOUD;
      signal.bearishScore = 1.0;
      signal.confidence   = MathMin(1.0, (prev.close - curr.close) / prevBody);
      return true;
   }

   /// Tweezer Top: two candles with matching (within tolerance) highs.
   /// Phase 1 simplification: shape-matching only, no trend-context check
   /// (see the note in SinglePattern.mqh - same reasoning applies here).
   static bool DetectTweezerTop(const MqlRates &prev, const MqlRates &curr, PatternSignal &signal)
   {
      signal.Clear();

      double avgRange = (CCandleUtils::Range(prev) + CCandleUtils::Range(curr)) / 2.0;
      if(avgRange <= 0.0)
         return false;

      double tolerance = avgRange * InpTweezerTolerance;
      double highDiff  = MathAbs(prev.high - curr.high);
      if(highDiff > tolerance)
         return false;

      signal.type         = PATTERN_TWEEZER_TOP;
      signal.bearishScore = 1.0;
      signal.confidence   = MathMax(0.0, 1.0 - (highDiff / tolerance));
      return true;
   }

   /// Tweezer Bottom: two candles with matching (within tolerance) lows.
   static bool DetectTweezerBottom(const MqlRates &prev, const MqlRates &curr, PatternSignal &signal)
   {
      signal.Clear();

      double avgRange = (CCandleUtils::Range(prev) + CCandleUtils::Range(curr)) / 2.0;
      if(avgRange <= 0.0)
         return false;

      double tolerance = avgRange * InpTweezerTolerance;
      double lowDiff   = MathAbs(prev.low - curr.low);
      if(lowDiff > tolerance)
         return false;

      signal.type         = PATTERN_TWEEZER_BOTTOM;
      signal.bullishScore = 1.0;
      signal.confidence   = MathMax(0.0, 1.0 - (lowDiff / tolerance));
      return true;
   }
};
//+------------------------------------------------------------------+
