//+------------------------------------------------------------------+
//| Test_ExecutionFilter.mq5                                           |
//| Standalone script - run manually in MT5 (Navigator > Scripts).    |
//| Feeds plain spread/hour values into ExecutionFilter - no broker    |
//| connection needed since CheckSpread/CheckSession take terminal-    |
//| derived values as parameters instead of reading them internally.  |
//|                                                                    |
//| Uses the default Config.mqh values:                                 |
//|   InpMaxSpreadPoints = 30, InpUseSessionFilter = true,               |
//|   InpSessionStartHour = 7, InpSessionEndHour = 21                   |
//+------------------------------------------------------------------+
#property strict
#property script_show_inputs

#include "TestFramework.mqh"
#include "../Risk/ExecutionFilter.mqh"

void OnStart()
{
   Print("=== Test_ExecutionFilter START ===");

   CExecutionFilter filter;

   //--- Spread checks
   Assert(filter.CheckSpread(10) == true,  "Spread 10 (well under 30) passes");
   Assert(filter.CheckSpread(30) == true,  "Spread exactly at 30 passes (boundary is inclusive)");
   Assert(filter.CheckSpread(31) == false, "Spread 31 (over 30) fails");

   //--- Session checks (default session 7-21, start < end, no wraparound)
   Assert(filter.CheckSession(10) == true,  "Hour 10 is inside the 7-21 session");
   Assert(filter.CheckSession(7)  == true,  "Hour 7 (session start) is inside - inclusive start");
   Assert(filter.CheckSession(21) == false, "Hour 21 (session end) is outside - exclusive end");
   Assert(filter.CheckSession(6)  == false, "Hour 6 (before session start) is outside");
   Assert(filter.CheckSession(22) == false, "Hour 22 (after session end) is outside");

   //--- Combined TickCheck
   Assert(filter.TickCheck(10, 10) == true,  "Good spread + good session hour => TickCheck passes");
   Assert(filter.TickCheck(50, 10) == false, "Bad spread alone fails TickCheck");
   Assert(filter.TickCheck(10, 3)  == false, "Bad session hour alone fails TickCheck");

   //--- MarketCheck is a Phase 1 no-op seam - should always pass for now
   Assert(filter.MarketCheck(0.0)    == true, "MarketCheck is a no-op in Phase 1 (any ATR passes)");
   Assert(filter.MarketCheck(0.0050) == true, "MarketCheck is a no-op in Phase 1 (any ATR passes)");

   PrintTestSummary("Test_ExecutionFilter");
}
//+------------------------------------------------------------------+
