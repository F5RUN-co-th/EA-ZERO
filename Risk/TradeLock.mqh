//+------------------------------------------------------------------+
//| TradeLock.mqh                                                      |
//| Guards against opening more trades than intended:                  |
//|  - one trade per bar (InpOneTradePerBar)                           |
//|  - max concurrent open positions (InpMaxOpenPositions)             |
//|                                                                    |
//| NOTE: given the current architecture (EA.mq5 only evaluates and    |
//| executes once per new bar, via IsNewBar()), the "one trade per     |
//| bar" check is structurally redundant right now - IsNewBar() already|
//| guarantees at most one Execute() attempt per bar. It's kept anyway |
//| as a defense-in-depth safety net (cheap insurance against a future |
//| change to the OnTick() gating logic), which is standard practice   |
//| in trading systems where a single risk-logic bug can be costly.    |
//| The max-open-positions check is NOT redundant: SystemState ==      |
//| IN_TRADE alone doesn't stop EA.mq5 from evaluating a new signal on  |
//| the next bar, so this is what actually prevents a second entry     |
//| while a position is still open.                                    |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Config.mqh"

class CTradeLock
{
private:
   datetime m_lastTradeBarTime;

public:
   CTradeLock() { m_lastTradeBarTime = 0; }

   /// @param currentBarTime     Time of the bar currently being evaluated (caller's g_lastBarTime).
   /// @param openPositionsCount How many positions this EA/symbol currently has open (caller counts).
   bool Blocked(datetime currentBarTime, int openPositionsCount)
   {
      if(InpOneTradePerBar && currentBarTime == m_lastTradeBarTime)
         return true;

      if(openPositionsCount >= InpMaxOpenPositions)
         return true;

      return false;
   }

   /// Call immediately after a trade is successfully opened, so a second
   /// Blocked() check later on the same bar correctly reports "already
   /// traded this bar" even before the new position shows up in a
   /// position count.
   void RegisterTradeOpened(datetime barTime)
   {
      m_lastTradeBarTime = barTime;
   }
};
//+------------------------------------------------------------------+
