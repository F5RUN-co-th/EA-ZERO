//+------------------------------------------------------------------+
//| ExecutionFilter.mqh                                               |
//| Cheap pre-trade gating: spread + session time (tick-level, no      |
//| price history needed) and a reserved market-level seam for future  |
//| ATR/volatility-based filters.                                     |
//|                                                                    |
//| Same "push side-effecting calls to the caller" pattern as          |
//| Strategy/StateMachine.mqh: this class never calls                  |
//| SymbolInfoInteger()/TimeCurrent() itself - EA.mq5 reads those and   |
//| passes the values in, which is what makes CheckSpread/CheckSession |
//| unit-testable with plain numbers (see Tests/Test_ExecutionFilter). |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Config.mqh"

class CExecutionFilter
{
public:
   /// Pure logic - testable without a terminal connection.
   bool CheckSpread(long currentSpreadPoints)
   {
      return currentSpreadPoints <= (long)InpMaxSpreadPoints;
   }

   /// Pure logic - testable without a terminal connection.
   /// @param currentHour Broker-time hour (0-23) of TimeCurrent(), read by the caller.
   bool CheckSession(int currentHour)
   {
      if(!InpUseSessionFilter)
         return true;

      if(InpSessionStartHour <= InpSessionEndHour)
         return (currentHour >= InpSessionStartHour && currentHour < InpSessionEndHour);

      // Overnight session that wraps past midnight, e.g. start=22, end=6
      return (currentHour >= InpSessionStartHour || currentHour < InpSessionEndHour);
   }

   /// Cheap tick-level gate - call this BEFORE MarketData.Update() so a
   /// bad spread/session rejects the bar without paying for CopyRates()/ATR.
   bool TickCheck(long currentSpreadPoints, int currentHour)
   {
      return CheckSpread(currentSpreadPoints) && CheckSession(currentHour);
   }

   /// Market-level gate - needs price history (e.g. ATR), so it only makes
   /// sense to call this AFTER MarketData.Update(). Phase 1: no additional
   /// filter is implemented yet (no backtest evidence to justify one) -
   /// this seam exists so RiskManager/EA.mq5 don't need to change again
   /// once a real market-level filter (e.g. "skip if ATR is too low") is
   /// actually needed.
   bool MarketCheck(double atr)
   {
      return true;
   }
};
//+------------------------------------------------------------------+
