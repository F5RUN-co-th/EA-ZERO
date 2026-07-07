//+------------------------------------------------------------------+
//| TriplePattern.mqh                                                  |
//| Detects three-candle patterns: Morning Star, Evening Star,        |
//| Three White Soldiers, Three Black Crows.                          |
//|                                                                    |
//| NOTE (Phase 1 simplification): textbook Morning/Evening Star       |
//| definitions require the middle "star" candle's body to gap away    |
//| from the first candle's body. Forex trades near-continuously and   |
//| rarely gaps between consecutive candles (unlike stock exchanges),  |
//| so requiring a strict gap would make these patterns almost never   |
//| fire. Instead this uses the common relaxed version: a small middle |
//| body, plus the third candle recovering meaningfully past the       |
//| first candle's midpoint. Confidence scales with how far past the   |
//| midpoint the recovery reaches.                                     |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Types.mqh"
#include "../Core/Config.mqh"
#include "../Utils/CandleUtils.mqh"

class CTriplePattern
{
public:
   /// c1 = oldest candle, c2 = middle candle, c3 = newest (just-closed) candle.
   static bool DetectMorningStar(const MqlRates &c1, const MqlRates &c2, const MqlRates &c3, PatternSignal &signal)
   {
      signal.Clear();

      if(!CCandleUtils::IsBearish(c1) || !CCandleUtils::IsBullish(c3))
         return false;

      double c1Body = CCandleUtils::BodySize(c1);
      double c2Body = CCandleUtils::BodySize(c2);
      double c3Body = CCandleUtils::BodySize(c3);

      if(c1Body <= 0.0 || c3Body <= 0.0)
         return false;

      // Middle candle must be a small "star" body relative to both outer candles
      if(c2Body > c1Body * InpStarMaxBodyRatio || c2Body > c3Body * InpStarMaxBodyRatio)
         return false;

      // Third candle must recover past the first candle's midpoint
      double c1Mid = CCandleUtils::MidPoint(c1);
      if(c3.close <= c1Mid)
         return false;

      double halfBody1 = c1.open - c1Mid; // c1 bearish: open > mid, always positive here
      if(halfBody1 <= 0.0)
         return false;

      signal.type         = PATTERN_MORNING_STAR;
      signal.bullishScore = 1.0;
      signal.confidence   = MathMax(0.0, MathMin(1.0, (c3.close - c1Mid) / halfBody1));
      return true;
   }

   /// c1 = oldest candle, c2 = middle candle, c3 = newest (just-closed) candle.
   static bool DetectEveningStar(const MqlRates &c1, const MqlRates &c2, const MqlRates &c3, PatternSignal &signal)
   {
      signal.Clear();

      if(!CCandleUtils::IsBullish(c1) || !CCandleUtils::IsBearish(c3))
         return false;

      double c1Body = CCandleUtils::BodySize(c1);
      double c2Body = CCandleUtils::BodySize(c2);
      double c3Body = CCandleUtils::BodySize(c3);

      if(c1Body <= 0.0 || c3Body <= 0.0)
         return false;

      if(c2Body > c1Body * InpStarMaxBodyRatio || c2Body > c3Body * InpStarMaxBodyRatio)
         return false;

      double c1Mid = CCandleUtils::MidPoint(c1);
      if(c3.close >= c1Mid)
         return false;

      double halfBody1 = c1Mid - c1.open; // c1 bullish: mid > open, always positive here
      if(halfBody1 <= 0.0)
         return false;

      signal.type         = PATTERN_EVENING_STAR;
      signal.bearishScore = 1.0;
      signal.confidence   = MathMax(0.0, MathMin(1.0, (c1Mid - c3.close) / halfBody1));
      return true;
   }

   /// Three White Soldiers: three consecutive bullish candles, each closing
   /// higher than the last, each with a small upper shadow (strong closes).
   static bool DetectThreeWhiteSoldiers(const MqlRates &c1, const MqlRates &c2, const MqlRates &c3, PatternSignal &signal)
   {
      signal.Clear();

      if(!CCandleUtils::IsBullish(c1) || !CCandleUtils::IsBullish(c2) || !CCandleUtils::IsBullish(c3))
         return false;

      if(!(c2.close > c1.close && c3.close > c2.close))
         return false;

      double body1 = CCandleUtils::BodySize(c1);
      double body2 = CCandleUtils::BodySize(c2);
      double body3 = CCandleUtils::BodySize(c3);
      if(body1 <= 0.0 || body2 <= 0.0 || body3 <= 0.0)
         return false;

      double upper1 = CCandleUtils::UpperShadow(c1);
      double upper2 = CCandleUtils::UpperShadow(c2);
      double upper3 = CCandleUtils::UpperShadow(c3);
      if(upper1 > body1 * InpSoldiersMaxShadowRatio ||
         upper2 > body2 * InpSoldiersMaxShadowRatio ||
         upper3 > body3 * InpSoldiersMaxShadowRatio)
         return false;

      signal.type         = PATTERN_THREE_WHITE_SOLDIERS;
      signal.bullishScore = 1.0;
      signal.confidence   = 1.0;
      return true;
   }

   /// Three Black Crows: mirror of Three White Soldiers.
   static bool DetectThreeBlackCrows(const MqlRates &c1, const MqlRates &c2, const MqlRates &c3, PatternSignal &signal)
   {
      signal.Clear();

      if(!CCandleUtils::IsBearish(c1) || !CCandleUtils::IsBearish(c2) || !CCandleUtils::IsBearish(c3))
         return false;

      if(!(c2.close < c1.close && c3.close < c2.close))
         return false;

      double body1 = CCandleUtils::BodySize(c1);
      double body2 = CCandleUtils::BodySize(c2);
      double body3 = CCandleUtils::BodySize(c3);
      if(body1 <= 0.0 || body2 <= 0.0 || body3 <= 0.0)
         return false;

      double lower1 = CCandleUtils::LowerShadow(c1);
      double lower2 = CCandleUtils::LowerShadow(c2);
      double lower3 = CCandleUtils::LowerShadow(c3);
      if(lower1 > body1 * InpSoldiersMaxShadowRatio ||
         lower2 > body2 * InpSoldiersMaxShadowRatio ||
         lower3 > body3 * InpSoldiersMaxShadowRatio)
         return false;

      signal.type         = PATTERN_THREE_BLACK_CROWS;
      signal.bearishScore = 1.0;
      signal.confidence   = 1.0;
      return true;
   }
};
//+------------------------------------------------------------------+
