//+------------------------------------------------------------------+
//| Test_EmergencyStop.mq5                                             |
//| Standalone script - run manually in MT5 (Navigator > Scripts).    |
//| Drives CEmergencyStop with fake equity values - no broker          |
//| connection or real account needed.                                 |
//|                                                                    |
//| Uses the default Config.mqh value:                                  |
//|   InpEmergencyMaxDrawdownPercent = 20.0                              |
//+------------------------------------------------------------------+
#property strict
#property script_show_inputs

#include "TestFramework.mqh"
#include "../Risk/EmergencyStop.mqh"

void OnStart()
{
   Print("=== Test_EmergencyStop START ===");

   //--- Fixture 1: no drawdown at all => not triggered
   {
      CEmergencyStop es;
      es.Init(10000.0);
      Assert(es.IsTriggered(10000.0) == false, "No drawdown from peak => not triggered");
   }

   //--- Fixture 2: 5% drawdown (well under 20%) => not triggered
   {
      CEmergencyStop es;
      es.Init(10000.0);
      Assert(es.IsTriggered(9500.0) == false, "5% drawdown (under 20%) => not triggered");
   }

   //--- Fixture 3: 21% drawdown (over the 20% threshold) => triggered
   {
      CEmergencyStop es;
      es.Init(10000.0);
      Assert(es.IsTriggered(7900.0) == true, "21% drawdown (over 20%) => triggered");
   }

   //--- Fixture 4: exactly 20% drawdown => triggered (boundary is inclusive, >=)
   {
      CEmergencyStop es;
      es.Init(10000.0);
      Assert(es.IsTriggered(8000.0) == true, "Exactly 20% drawdown => triggered (inclusive boundary)");
   }

   //--- Fixture 5: peak tracks upward as equity grows, recalculating drawdown from the NEW peak
   {
      CEmergencyStop es;
      es.Init(10000.0);
      Assert(es.IsTriggered(11000.0) == false, "New equity high (11000) becomes the new peak, not triggered");
      Assert(AlmostEqual(es.PeakEquity(), 11000.0), "PeakEquity() reflects the new high");

      // 19.09% drawdown from the new peak of 11000 - still under 20%
      Assert(es.IsTriggered(8900.0) == false, "19.09% drawdown from the NEW peak (11000) => not triggered");

      // ~20.9% drawdown from the new peak - now triggered
      Assert(es.IsTriggered(8700.0) == true, "~20.9% drawdown from the NEW peak (11000) => triggered");
   }

   PrintTestSummary("Test_EmergencyStop");
}
//+------------------------------------------------------------------+
