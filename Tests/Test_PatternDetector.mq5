//+------------------------------------------------------------------+
//| Test_PatternDetector.mq5                                          |
//| Standalone script - run manually in MT5 (Navigator > Scripts).    |
//| Feeds hand-built candle fixtures (known answers) into              |
//| SinglePattern / DoublePattern / PatternDetector.Scan() and checks  |
//| the output. This is the integration layer unit tests can't see:   |
//| bugs from modules not agreeing with each other (e.g. field names, |
//| as-series ordering) show up here even if each function is         |
//| individually correct.                                             |
//|                                                                    |
//| Uses the default Config.mqh thresholds:                           |
//|   InpDojiMaxBodyRatio = 0.1, InpMarubozuMinBodyRatio = 0.9,        |
//|   InpHammerMinShadowRatio = 2.0, InpHammerMaxOppositeShadowRatio = 0.25 |
//| If you change those inputs, the numbers picked below may need     |
//| updating to match.                                                |
//+------------------------------------------------------------------+
#property strict
#property script_show_inputs

#include "TestFramework.mqh"
#include "../Core/Interfaces.mqh"
#include "../Pattern/PatternDetector.mqh"

void OnStart()
{
   Print("=== Test_PatternDetector START ===");

   //--- Fixture 1: textbook Hammer
   //    body=0.0005, lowerShadow=0.0040 (>= body*2.0), upperShadow=0.0000 (<= body*0.25)
   {
      MqlRates hammer = MakeCandle(1.1030, 1.1035, 1.0990, 1.1035);
      PatternSignal s;
      bool found = CSinglePattern::Detect(hammer, s);
      Assert(found,                              "Hammer shape is detected");
      Assert(s.type == PATTERN_HAMMER,           "Detected type is PATTERN_HAMMER");
      Assert(s.bullishScore > 0.0,                "Hammer contributes a bullish score");
   }

   //--- Fixture 2: textbook Doji (open == close)
   {
      MqlRates doji = MakeCandle(1.1000, 1.1030, 1.0970, 1.1000);
      PatternSignal s;
      bool found = CSinglePattern::Detect(doji, s);
      Assert(found,                              "Doji shape is detected");
      Assert(s.type == PATTERN_DOJI,              "Detected type is PATTERN_DOJI");
      Assert(s.neutralScore > 0.0,                "Doji contributes a neutral score, not directional");
   }

   //--- Fixture 3: textbook Bullish Engulfing
   //    prev = small red candle, curr = bigger green candle that fully engulfs prev's body
   {
      MqlRates prevBearish = MakeCandle(1.1020, 1.1025, 1.0995, 1.1000);
      MqlRates currBullish = MakeCandle(1.0995, 1.1035, 1.0990, 1.1030);
      PatternSignal s;
      bool found = CDoublePattern::DetectBullishEngulfing(prevBearish, currBullish, s);
      Assert(found,                                       "Bullish Engulfing is detected");
      Assert(s.type == PATTERN_BULLISH_ENGULFING,         "Detected type is PATTERN_BULLISH_ENGULFING");
      Assert(s.bullishScore > 0.0,                         "Bullish Engulfing contributes a bullish score");
   }

   //--- Fixture 4: a plain trending candle that should NOT trigger any single pattern
   //    body=0.0030, range=0.0040, bodyRatio=0.75 (between Doji and Marubozu thresholds,
   //    shadows too short for Hammer/Shooting Star, too short for Spinning Top too)
   {
      MqlRates plain = MakeCandle(1.1000, 1.1035, 1.0995, 1.1030);
      PatternSignal s;
      bool found = CSinglePattern::Detect(plain, s);
      Assert(!found, "Plain trending candle does not falsely trigger a shape pattern");
   }

   //--- Fixture 5: full PatternDetector.Scan() over a 3-bar as-series array
   //    rates[0] = still-forming bar (must be ignored by Scan)
   //    rates[1] = newest CLOSED bar (green, engulfs rates[2])
   //    rates[2] = older bar (red)
   {
      MqlRates rates[3];
      rates[0] = MakeCandle(1.1030, 1.1040, 1.1020, 1.1035); // forming, ignored
      rates[1] = MakeCandle(1.0995, 1.1035, 1.0990, 1.1030); // green, engulfs rates[2]
      rates[2] = MakeCandle(1.1020, 1.1025, 1.0995, 1.1000); // red

      CPatternDetector detector;
      PatternSignal signals[];
      detector.Scan(rates, signals);

      Assert(ArraySize(signals) > 0, "Scan() finds at least one signal in the 3-bar fixture");

      bool foundEngulfing = false;
      for(int i = 0; i < ArraySize(signals); i++)
         if(signals[i].type == PATTERN_BULLISH_ENGULFING)
            foundEngulfing = true;

      Assert(foundEngulfing, "Scan() finds the Bullish Engulfing across rates[2]->rates[1]");
   }

   PrintTestSummary("Test_PatternDetector");
}
//+------------------------------------------------------------------+
