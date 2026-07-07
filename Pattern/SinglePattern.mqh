//+------------------------------------------------------------------+
//| SinglePattern.mqh                                                 |
//| Detects single-candle shapes: Hammer, Shooting Star, Doji,        |
//| Bullish/Bearish Marubozu, Spinning Top.                           |
//|                                                                    |
//| NOTE (Phase 1 scope): Hammer and Hanging Man are the exact same   |
//| shape - the difference is whether the prior trend was down or up. |
//| Same for Inverted Hammer vs Shooting Star. Telling them apart      |
//| needs trend/Market Structure context, which is a Phase 2 feature   |
//| (IFeature). For Phase 1 this classifies by shape only and always  |
//| resolves the shape to its bullish-context name (Hammer) or        |
//| bearish-context name (Shooting Star) - Classification/DecisionEngine|
//| can be refined once Phase 2 trend context exists.                 |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Types.mqh"
#include "../Core/Config.mqh"
#include "../Utils/CandleUtils.mqh"

class CSinglePattern
{
public:
   /// Classifies the shape of a single candle.
   /// @return true if a known shape was found; signal is filled in.
   static bool Detect(const MqlRates &r, PatternSignal &signal)
   {
      signal.Clear();

      double body       = CCandleUtils::BodySize(r);
      double range       = CCandleUtils::Range(r);
      double upperShadow = CCandleUtils::UpperShadow(r);
      double lowerShadow = CCandleUtils::LowerShadow(r);

      if(range <= 0.0)
         return false; // flat/zero-range bar, nothing meaningful to classify

      double bodyRatio = body / range;

      //--- Doji: body is negligible compared to the full range
      if(bodyRatio <= InpDojiMaxBodyRatio)
      {
         signal.type         = PATTERN_DOJI;
         signal.confidence   = 1.0 - (bodyRatio / InpDojiMaxBodyRatio);
         signal.neutralScore = 1.0;
         return true;
      }

      //--- Marubozu: body takes up almost the whole range, either direction
      if(bodyRatio >= InpMarubozuMinBodyRatio)
      {
         bool bullish = CCandleUtils::IsBullish(r);
         signal.type       = bullish ? PATTERN_BULLISH_MARUBOZU : PATTERN_BEARISH_MARUBOZU;
         signal.confidence = MathMin(1.0, 0.5 + (bodyRatio - InpMarubozuMinBodyRatio) / (1.0 - InpMarubozuMinBodyRatio));

         if(bullish)
            signal.bullishScore = 1.0;
         else
            signal.bearishScore = 1.0;

         return true;
      }

      //--- Hammer shape: long lower shadow, small upper shadow, small body
      if(body > 0.0 &&
         lowerShadow >= body * InpHammerMinShadowRatio &&
         upperShadow <= body * InpHammerMaxOppositeShadowRatio)
      {
         signal.type         = PATTERN_HAMMER;
         signal.confidence   = MathMin(1.0, lowerShadow / (body * InpHammerMinShadowRatio));
         signal.bullishScore = 1.0; // Phase 1 default - refined by trend context in Phase 2
         return true;
      }

      //--- Shooting Star shape: long upper shadow, small lower shadow, small body
      if(body > 0.0 &&
         upperShadow >= body * InpHammerMinShadowRatio &&
         lowerShadow <= body * InpHammerMaxOppositeShadowRatio)
      {
         signal.type         = PATTERN_SHOOTING_STAR;
         signal.confidence   = MathMin(1.0, upperShadow / (body * InpHammerMinShadowRatio));
         signal.bearishScore = 1.0;
         return true;
      }

      //--- Spinning Top: small-ish body, both shadows noticeable and roughly balanced
      if(upperShadow > body * 0.5 && lowerShadow > body * 0.5)
      {
         signal.type         = PATTERN_SPINNING_TOP;
         signal.confidence   = 0.5;
         signal.neutralScore = 1.0;
         return true;
      }

      return false; // no known shape - just an ordinary trending candle
   }
};
//+------------------------------------------------------------------+
