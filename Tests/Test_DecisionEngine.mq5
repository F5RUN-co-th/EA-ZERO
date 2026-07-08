//+------------------------------------------------------------------+
//| Test_DecisionEngine.mq5                                            |
//| Standalone script - run manually in MT5 (Navigator > Scripts).    |
//| Feeds hand-picked bull/bear/neutral scores into DecisionEngine and |
//| checks the resulting TradeDirection.                              |
//|                                                                    |
//| Uses the default Config.mqh values:                                |
//|   InpMinScoreThreshold = 1.0, InpDominanceRatio = 1.2               |
//| If you change those inputs, the numbers picked below may need     |
//| updating to match.                                                |
//+------------------------------------------------------------------+
#property strict
#property script_show_inputs

#include "TestFramework.mqh"
#include "../Core/Interfaces.mqh"
#include "../Strategy/DecisionEngine.mqh"

void OnStart()
{
   Print("=== Test_DecisionEngine START ===");

   CDecisionEngine engine;

   //--- Fixture 1: bull clearly dominates (3.0 vs 1.0, ratio 3.0 > 1.2) => BUY
   {
      TradeDirection d = engine.Decide(3.0, 1.0, 0.0);
      Assert(d == DIRECTION_BUY, "Bull clearly dominates bear => DIRECTION_BUY");
   }

   //--- Fixture 2: bear clearly dominates (mirror of Fixture 1) => SELL
   {
      TradeDirection d = engine.Decide(1.0, 3.0, 0.0);
      Assert(d == DIRECTION_SELL, "Bear clearly dominates bull => DIRECTION_SELL");
   }

   //--- Fixture 3: both above threshold but too close in ratio (1.5 vs 1.4) => NONE
   {
      TradeDirection d = engine.Decide(1.5, 1.4, 0.0);
      Assert(d == DIRECTION_NONE, "Scores too close in ratio (no clear dominance) => DIRECTION_NONE");
   }

   //--- Fixture 4: ratio would qualify, but both scores are below the minimum threshold => NONE
   {
      TradeDirection d = engine.Decide(0.5, 0.1, 0.0);
      Assert(d == DIRECTION_NONE, "Scores too weak overall (below InpMinScoreThreshold) => DIRECTION_NONE");
   }

   //--- Fixture 5: no signals at all => NONE
   {
      TradeDirection d = engine.Decide(0.0, 0.0, 0.0);
      Assert(d == DIRECTION_NONE, "No signals at all => DIRECTION_NONE");
   }

   //--- Fixture 6: a large neutral score does NOT suppress an otherwise-clear bullish decision
   //    (documented Phase 1 scope - see the NOTE at the top of DecisionEngine.mqh)
   {
      TradeDirection d = engine.Decide(3.0, 1.0, 100.0);
      Assert(d == DIRECTION_BUY, "A large neutralScore does not suppress a clear BUY (Phase 1 scope)");
   }

   PrintTestSummary("Test_DecisionEngine");
}
//+------------------------------------------------------------------+
