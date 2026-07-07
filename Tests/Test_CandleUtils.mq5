//+------------------------------------------------------------------+
//| Test_CandleUtils.mq5                                              |
//| Standalone script - run manually in MT5 (Navigator > Scripts).    |
//| Verifies Utils/CandleUtils.mqh math against hand-computed values. |
//| No chart trading logic is involved; this only tests pure math.    |
//+------------------------------------------------------------------+
#property strict
#property script_show_inputs

#include "TestFramework.mqh"
#include "../Utils/CandleUtils.mqh"

//+------------------------------------------------------------------+
void OnStart()
{
   Print("=== Test_CandleUtils START ===");

   //--- Bullish candle: open 1.1000, high 1.1050, low 1.0980, close 1.1040
   MqlRates bull = MakeCandle(1.1000, 1.1050, 1.0980, 1.1040);
   Assert(AlmostEqual(CCandleUtils::BodySize(bull), 0.0040),     "Bullish BodySize");
   Assert(AlmostEqual(CCandleUtils::UpperShadow(bull), 0.0010),  "Bullish UpperShadow");
   Assert(AlmostEqual(CCandleUtils::LowerShadow(bull), 0.0020),  "Bullish LowerShadow");
   Assert(AlmostEqual(CCandleUtils::Range(bull), 0.0070),        "Bullish Range");
   Assert(CCandleUtils::IsBullish(bull) == true,                 "Bullish IsBullish == true");
   Assert(CCandleUtils::IsBearish(bull) == false,                "Bullish IsBearish == false");
   Assert(AlmostEqual(CCandleUtils::MidPoint(bull), 1.1020),     "Bullish MidPoint");

   //--- Bearish candle: open 1.1040, high 1.1050, low 1.0980, close 1.1000
   MqlRates bear = MakeCandle(1.1040, 1.1050, 1.0980, 1.1000);
   Assert(AlmostEqual(CCandleUtils::BodySize(bear), 0.0040), "Bearish BodySize");
   Assert(CCandleUtils::IsBullish(bear) == false,            "Bearish IsBullish == false");
   Assert(CCandleUtils::IsBearish(bear) == true,             "Bearish IsBearish == true");

   //--- Doji: open ~= close, body should be small relative to range
   MqlRates doji = MakeCandle(1.1000, 1.1030, 1.0970, 1.1002);
   Assert(CCandleUtils::BodySize(doji) < 0.0010, "Doji BodySize is small");

   //--- Bullish Marubozu: no shadows at all (open==low, close==high)
   MqlRates marubozu = MakeCandle(1.1000, 1.1050, 1.1000, 1.1050);
   Assert(AlmostEqual(CCandleUtils::UpperShadow(marubozu), 0.0), "Marubozu UpperShadow == 0");
   Assert(AlmostEqual(CCandleUtils::LowerShadow(marubozu), 0.0), "Marubozu LowerShadow == 0");

   //--- ATRNormalize
   Assert(AlmostEqual(CCandleUtils::ATRNormalize(0.0040, 0.0020), 2.0), "ATRNormalize 0.0040/0.0020 == 2.0");
   Assert(AlmostEqual(CCandleUtils::ATRNormalize(0.0040, 0.0), 0.0),    "ATRNormalize with zero ATR returns 0.0");

   PrintTestSummary("Test_CandleUtils");
}
//+------------------------------------------------------------------+
