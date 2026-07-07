//+------------------------------------------------------------------+
//| Test_PatternClassifier.mq5                                        |
//| Standalone script - run manually in MT5 (Navigator > Scripts).    |
//| Builds PatternSignal fixtures by hand (bypassing the detector      |
//| entirely) to verify the weight-lookup and aggregation math in     |
//| Classification/PatternClassifier.mqh.                             |
//|                                                                    |
//| Uses the default Config.mqh weights:                               |
//|   InpWeightHammer = 1.0, InpWeightBearishEngulfing = 1.5           |
//| If you change those inputs, the expected numbers below may need   |
//| updating to match.                                                 |
//+------------------------------------------------------------------+
#property strict
#property script_show_inputs

#include "TestFramework.mqh"
#include "../Classification/PatternClassifier.mqh"

void OnStart()
{
   Print("=== Test_PatternClassifier START ===");

   CPatternClassifier classifier;

   //--- Fixture 1: empty signal list => all scores zero
   {
      PatternSignal signals[];
      double bull, bear, neutral;
      classifier.Score(signals, bull, bear, neutral);
      Assert(AlmostEqual(bull, 0.0) && AlmostEqual(bear, 0.0) && AlmostEqual(neutral, 0.0),
             "Empty signal list produces all-zero scores");
   }

   //--- Fixture 2: one full-confidence Hammer => bull score == InpWeightHammer
   {
      PatternSignal signals[1];
      signals[0].Clear();
      signals[0].type         = PATTERN_HAMMER;
      signals[0].bullishScore = 1.0;
      signals[0].confidence   = 1.0;

      double bull, bear, neutral;
      classifier.Score(signals, bull, bear, neutral);

      Assert(AlmostEqual(bull, InpWeightHammer), "Single full-confidence Hammer == InpWeightHammer");
      Assert(AlmostEqual(bear, 0.0),              "Hammer fixture contributes nothing to bearish score");
   }

   //--- Fixture 3: one half-confidence Bearish Engulfing => bear score == weight * 0.5
   {
      PatternSignal signals[1];
      signals[0].Clear();
      signals[0].type         = PATTERN_BEARISH_ENGULFING;
      signals[0].bearishScore = 1.0;
      signals[0].confidence   = 0.5;

      double bull, bear, neutral;
      classifier.Score(signals, bull, bear, neutral);

      double expected = InpWeightBearishEngulfing * 0.5;
      Assert(AlmostEqual(bear, expected), "Half-confidence Bearish Engulfing == weight * 0.5");
   }

   //--- Fixture 4: unknown/unweighted type (PATTERN_NONE) contributes nothing, even with scores set
   {
      PatternSignal signals[1];
      signals[0].Clear();
      signals[0].type         = PATTERN_NONE;
      signals[0].bullishScore = 1.0;
      signals[0].confidence   = 1.0;

      double bull, bear, neutral;
      classifier.Score(signals, bull, bear, neutral);

      Assert(AlmostEqual(bull, 0.0), "PATTERN_NONE has zero weight, contributes nothing even with bullishScore set");
   }

   //--- Fixture 5: multiple signals accumulate additively
   {
      PatternSignal signals[2];
      signals[0].Clear();
      signals[0].type         = PATTERN_HAMMER;
      signals[0].bullishScore = 1.0;
      signals[0].confidence   = 1.0;

      signals[1].Clear();
      signals[1].type         = PATTERN_BULLISH_MARUBOZU;
      signals[1].bullishScore = 1.0;
      signals[1].confidence   = 1.0;

      double bull, bear, neutral;
      classifier.Score(signals, bull, bear, neutral);

      double expected = InpWeightHammer + InpWeightBullishMarubozu;
      Assert(AlmostEqual(bull, expected), "Two signals accumulate additively into the bullish score");
   }

   PrintTestSummary("Test_PatternClassifier");
}
//+------------------------------------------------------------------+
