//+------------------------------------------------------------------+
//| Test_TradeLock.mq5                                                 |
//| Standalone script - run manually in MT5 (Navigator > Scripts).    |
//| Drives CTradeLock with fake bar times and position counts - no     |
//| broker connection needed.                                          |
//|                                                                    |
//| Uses the default Config.mqh values:                                 |
//|   InpOneTradePerBar = true, InpMaxOpenPositions = 1                 |
//+------------------------------------------------------------------+
#property strict
#property script_show_inputs

#include "TestFramework.mqh"
#include "../Risk/TradeLock.mqh"

void OnStart()
{
   Print("=== Test_TradeLock START ===");

   //--- Fixture 1: fresh lock, no positions, nothing traded yet => not blocked
   {
      CTradeLock lock;
      Assert(lock.Blocked(1000, 0) == false, "Fresh TradeLock with 0 open positions is not blocked");
   }

   //--- Fixture 2: after registering a trade on a bar, the SAME bar is blocked
   {
      CTradeLock lock;
      lock.RegisterTradeOpened(1000);
      Assert(lock.Blocked(1000, 0) == true,
             "Same bar as the registered trade is blocked (one trade per bar), even with 0 counted positions yet");
   }

   //--- Fixture 3: a DIFFERENT bar is not blocked by the one-trade-per-bar rule
   {
      CTradeLock lock;
      lock.RegisterTradeOpened(1000);
      Assert(lock.Blocked(2000, 0) == false, "A different bar time is not blocked by the per-bar rule");
   }

   //--- Fixture 4: max open positions blocks regardless of bar time
   {
      CTradeLock lock;
      lock.RegisterTradeOpened(1000);
      Assert(lock.Blocked(2000, 1) == true,
             "openPositionsCount >= InpMaxOpenPositions (1) blocks, even on a fresh bar");
   }

   //--- Fixture 5: below max open positions on a fresh bar is not blocked
   {
      CTradeLock lock;
      Assert(lock.Blocked(5000, 0) == false, "0 open positions (< max of 1) on a fresh bar is not blocked");
   }

   PrintTestSummary("Test_TradeLock");
}
//+------------------------------------------------------------------+
