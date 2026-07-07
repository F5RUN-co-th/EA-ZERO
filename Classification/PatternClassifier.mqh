//+------------------------------------------------------------------+
//| PatternClassifier.mqh                                              |
//| Implements IScorer. Converts a list of PatternSignal into          |
//| aggregated bullish/bearish/neutral scores.                        |
//|                                                                    |
//| Design note: PatternDetector deliberately assigns a flat 1.0 to    |
//| bullishScore/bearishScore/neutralScore for every pattern it finds  |
//| (a plain "this direction, yes/no" flag) - it does NOT decide that  |
//| a Morning Star matters more than a Hammer. That judgement belongs  |
//| here, via GetPatternWeight(), which reads a tunable `input` for    |
//| every pattern type so the Strategy Tester can optimize which       |
//| patterns actually matter for a given symbol/timeframe.             |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Interfaces.mqh"
#include "../Core/Config.mqh"

class CPatternClassifier : public IScorer
{
public:
   virtual void Score(const PatternSignal &signals[],
                       double &bullishScore,
                       double &bearishScore,
                       double &neutralScore)
   {
      bullishScore = 0.0;
      bearishScore = 0.0;
      neutralScore = 0.0;

      int total = ArraySize(signals);
      for(int i = 0; i < total; i++)
      {
         double weight     = GetPatternWeight(signals[i].type);
         double confidence = signals[i].confidence;
         double factor     = weight * confidence;

         bullishScore += signals[i].bullishScore * factor;
         bearishScore += signals[i].bearishScore * factor;
         neutralScore += signals[i].neutralScore * factor;
      }
   }

private:
   /// Maps a PatternType to its tunable weight input. PATTERN_NONE,
   /// PATTERN_HANGING_MAN, and PATTERN_INVERTED_HAMMER return 0.0 -
   /// the last two are declared in Types.mqh for Phase 2 but are not
   /// produced by any detector yet (see the note in SinglePattern.mqh).
   double GetPatternWeight(PatternType type)
   {
      switch(type)
      {
         case PATTERN_HAMMER:               return InpWeightHammer;
         case PATTERN_SHOOTING_STAR:        return InpWeightShootingStar;
         case PATTERN_DOJI:                 return InpWeightDoji;
         case PATTERN_SPINNING_TOP:         return InpWeightSpinningTop;
         case PATTERN_BULLISH_MARUBOZU:     return InpWeightBullishMarubozu;
         case PATTERN_BEARISH_MARUBOZU:     return InpWeightBearishMarubozu;
         case PATTERN_BULLISH_ENGULFING:    return InpWeightBullishEngulfing;
         case PATTERN_BEARISH_ENGULFING:    return InpWeightBearishEngulfing;
         case PATTERN_HARAMI_BULL:          return InpWeightHaramiBull;
         case PATTERN_HARAMI_BEAR:          return InpWeightHaramiBear;
         case PATTERN_PIERCING_LINE:        return InpWeightPiercingLine;
         case PATTERN_DARK_CLOUD:           return InpWeightDarkCloud;
         case PATTERN_TWEEZER_TOP:          return InpWeightTweezerTop;
         case PATTERN_TWEEZER_BOTTOM:       return InpWeightTweezerBottom;
         case PATTERN_MORNING_STAR:         return InpWeightMorningStar;
         case PATTERN_EVENING_STAR:         return InpWeightEveningStar;
         case PATTERN_THREE_WHITE_SOLDIERS: return InpWeightThreeWhiteSoldiers;
         case PATTERN_THREE_BLACK_CROWS:    return InpWeightThreeBlackCrows;
         default:                           return 0.0;
      }
   }
};
//+------------------------------------------------------------------+
