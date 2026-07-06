//+------------------------------------------------------------------+
//| CandleUtils.mqh                                                   |
//| Shared candle-math helpers used by every pattern detector.        |
//| Keeping these in one place avoids duplicated body/shadow math     |
//| across Single/Double/TriplePattern.mqh.                           |
//+------------------------------------------------------------------+
#property strict

class CCandleUtils
{
public:
   /// Absolute size of the candle body (close vs open).
   static double BodySize(const MqlRates &r)
   {
      return MathAbs(r.close - r.open);
   }

   /// Length of the upper wick/shadow.
   static double UpperShadow(const MqlRates &r)
   {
      return r.high - MathMax(r.open, r.close);
   }

   /// Length of the lower wick/shadow.
   static double LowerShadow(const MqlRates &r)
   {
      return MathMin(r.open, r.close) - r.low;
   }

   /// Full high-low range of the candle.
   static double Range(const MqlRates &r)
   {
      return r.high - r.low;
   }

   /// True if the candle closed above where it opened.
   static bool IsBullish(const MqlRates &r)
   {
      return r.close > r.open;
   }

   /// True if the candle closed below where it opened.
   static bool IsBearish(const MqlRates &r)
   {
      return r.close < r.open;
   }

   /// Midpoint price of the candle body.
   static double MidPoint(const MqlRates &r)
   {
      return (r.open + r.close) / 2.0;
   }

   /// Normalizes a raw price distance against ATR so pattern
   /// thresholds scale with current volatility instead of being
   /// fixed pip values.
   /// @param value Raw price distance (e.g. body size).
   /// @param atr   Current ATR value.
   /// @return value / atr, or 0.0 if atr is zero/invalid.
   static double ATRNormalize(double value, double atr)
   {
      if(atr <= 0.0)
         return 0.0;

      return value / atr;
   }
};
//+------------------------------------------------------------------+
