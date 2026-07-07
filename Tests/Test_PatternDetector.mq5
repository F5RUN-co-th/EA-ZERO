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

   //--- Fixture 6: Bullish Harami (prev large bearish, curr small body inside prev's body)
   {
      MqlRates prev = MakeCandle(1.1050, 1.1055, 1.0995, 1.1000); // bearish, body 0.0050
      MqlRates curr = MakeCandle(1.1020, 1.1035, 1.1015, 1.1030); // small body 0.0010, inside [1.1000,1.1050]
      PatternSignal s;
      bool found = CDoublePattern::DetectBullishHarami(prev, curr, s);
      Assert(found,                             "Bullish Harami is detected");
      Assert(s.type == PATTERN_HARAMI_BULL,     "Detected type is PATTERN_HARAMI_BULL");
      Assert(s.bullishScore > 0.0,               "Bullish Harami contributes a bullish score");
   }

   //--- Fixture 7: Bearish Harami (prev large bullish, curr small body inside prev's body)
   {
      MqlRates prev = MakeCandle(1.1000, 1.1055, 1.0995, 1.1050); // bullish, body 0.0050
      MqlRates curr = MakeCandle(1.1030, 1.1035, 1.1015, 1.1020); // small body 0.0010, inside [1.1000,1.1050]
      PatternSignal s;
      bool found = CDoublePattern::DetectBearishHarami(prev, curr, s);
      Assert(found,                             "Bearish Harami is detected");
      Assert(s.type == PATTERN_HARAMI_BEAR,     "Detected type is PATTERN_HARAMI_BEAR");
      Assert(s.bearishScore > 0.0,               "Bearish Harami contributes a bearish score");
   }

   //--- Fixture 8: Piercing Line (prev bearish, curr gaps down then closes past prev's midpoint)
   {
      MqlRates prev = MakeCandle(1.1050, 1.1055, 1.0995, 1.1000); // bearish, mid = 1.1025
      MqlRates curr = MakeCandle(1.0990, 1.1040, 1.0985, 1.1035); // opens below 1.1000, closes 1.1035 (>mid, <1.1050)
      PatternSignal s;
      bool found = CDoublePattern::DetectPiercingLine(prev, curr, s);
      Assert(found,                              "Piercing Line is detected");
      Assert(s.type == PATTERN_PIERCING_LINE,    "Detected type is PATTERN_PIERCING_LINE");
      Assert(s.bullishScore > 0.0,                "Piercing Line contributes a bullish score");

      // Sanity check: this should NOT also register as a full Bullish Engulfing
      // (it only partially penetrates prev's body, by definition)
      PatternSignal engulf;
      bool alsoEngulfing = CDoublePattern::DetectBullishEngulfing(prev, curr, engulf);
      Assert(!alsoEngulfing, "Piercing Line fixture is NOT also a Bullish Engulfing");
   }

   //--- Fixture 9: Dark Cloud Cover (mirror of Piercing Line)
   {
      MqlRates prev = MakeCandle(1.1000, 1.1055, 1.0995, 1.1050); // bullish, mid = 1.1025
      MqlRates curr = MakeCandle(1.1060, 1.1065, 1.1010, 1.1015); // opens above 1.1050, closes 1.1015 (<mid, >1.1000)
      PatternSignal s;
      bool found = CDoublePattern::DetectDarkCloudCover(prev, curr, s);
      Assert(found,                          "Dark Cloud Cover is detected");
      Assert(s.type == PATTERN_DARK_CLOUD,   "Detected type is PATTERN_DARK_CLOUD");
      Assert(s.bearishScore > 0.0,            "Dark Cloud Cover contributes a bearish score");
   }

   //--- Fixture 10: Tweezer Top (two candles with matching highs)
   {
      MqlRates prev = MakeCandle(1.1000, 1.1050, 1.0995, 1.1040); // high = 1.1050
      MqlRates curr = MakeCandle(1.1045, 1.1051, 1.1000, 1.1005); // high = 1.1051, almost equal
      PatternSignal s;
      bool found = CDoublePattern::DetectTweezerTop(prev, curr, s);
      Assert(found,                           "Tweezer Top is detected (matching highs)");
      Assert(s.type == PATTERN_TWEEZER_TOP,   "Detected type is PATTERN_TWEEZER_TOP");
   }

   //--- Fixture 11: Tweezer Bottom (two candles with matching lows)
   {
      MqlRates prev = MakeCandle(1.1030, 1.1040, 1.0990, 1.1000); // low = 1.0990
      MqlRates curr = MakeCandle(1.0995, 1.1045, 1.0991, 1.1035); // low = 1.0991, almost equal
      PatternSignal s;
      bool found = CDoublePattern::DetectTweezerBottom(prev, curr, s);
      Assert(found,                              "Tweezer Bottom is detected (matching lows)");
      Assert(s.type == PATTERN_TWEEZER_BOTTOM,   "Detected type is PATTERN_TWEEZER_BOTTOM");
   }

   //--- Fixture 12: Morning Star (bearish, small star, bullish recovery past midpoint)
   {
      MqlRates c1 = MakeCandle(1.1050, 1.1055, 1.0995, 1.1000); // bearish, body 0.0050, mid = 1.1025
      MqlRates c2 = MakeCandle(1.0995, 1.1000, 1.0985, 1.0990); // small star body 0.0005
      MqlRates c3 = MakeCandle(1.0995, 1.1045, 1.0990, 1.1040); // bullish, closes 1.1040 (past mid 1.1025)
      PatternSignal s;
      bool found = CTriplePattern::DetectMorningStar(c1, c2, c3, s);
      Assert(found,                            "Morning Star is detected");
      Assert(s.type == PATTERN_MORNING_STAR,   "Detected type is PATTERN_MORNING_STAR");
      Assert(s.bullishScore > 0.0,              "Morning Star contributes a bullish score");
   }

   //--- Fixture 13: Evening Star (mirror of Morning Star)
   {
      MqlRates c1 = MakeCandle(1.1000, 1.1055, 1.0995, 1.1050); // bullish, body 0.0050, mid = 1.1025
      MqlRates c2 = MakeCandle(1.1055, 1.1065, 1.1050, 1.1060); // small star body 0.0005
      MqlRates c3 = MakeCandle(1.1055, 1.1060, 1.1005, 1.1010); // bearish, closes 1.1010 (past mid 1.1025)
      PatternSignal s;
      bool found = CTriplePattern::DetectEveningStar(c1, c2, c3, s);
      Assert(found,                            "Evening Star is detected");
      Assert(s.type == PATTERN_EVENING_STAR,   "Detected type is PATTERN_EVENING_STAR");
      Assert(s.bearishScore > 0.0,              "Evening Star contributes a bearish score");
   }

   //--- Fixture 14: Three White Soldiers (3 bullish candles, each closing higher, small upper shadows)
   {
      MqlRates c1 = MakeCandle(1.1000, 1.1032, 1.0998, 1.1030);
      MqlRates c2 = MakeCandle(1.1015, 1.1058, 1.1010, 1.1055);
      MqlRates c3 = MakeCandle(1.1040, 1.1093, 1.1035, 1.1090);
      PatternSignal s;
      bool found = CTriplePattern::DetectThreeWhiteSoldiers(c1, c2, c3, s);
      Assert(found,                                    "Three White Soldiers is detected");
      Assert(s.type == PATTERN_THREE_WHITE_SOLDIERS,   "Detected type is PATTERN_THREE_WHITE_SOLDIERS");
      Assert(s.bullishScore > 0.0,                      "Three White Soldiers contributes a bullish score");
   }

   //--- Fixture 15: Three Black Crows (mirror of Three White Soldiers)
   {
      MqlRates c1 = MakeCandle(1.1090, 1.1092, 1.1058, 1.1060);
      MqlRates c2 = MakeCandle(1.1075, 1.1078, 1.1030, 1.1035);
      MqlRates c3 = MakeCandle(1.1050, 1.1053, 1.0997, 1.1000);
      PatternSignal s;
      bool found = CTriplePattern::DetectThreeBlackCrows(c1, c2, c3, s);
      Assert(found,                                 "Three Black Crows is detected");
      Assert(s.type == PATTERN_THREE_BLACK_CROWS,   "Detected type is PATTERN_THREE_BLACK_CROWS");
      Assert(s.bearishScore > 0.0,                   "Three Black Crows contributes a bearish score");
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
