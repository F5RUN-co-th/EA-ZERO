//+------------------------------------------------------------------+
//| EmergencyStop.mqh                                                  |
//| Master kill-switch: tracks the highest equity seen since Init(),   |
//| and triggers once the drawdown from that peak reaches               |
//| InpEmergencyMaxDrawdownPercent. Checked every tick, before anything |
//| else in OnTick() - see the flow comment at the top of EA.mq5.      |
//|                                                                    |
//| Same pattern as StateMachine/ExecutionFilter/TradeLock: equity is   |
//| passed in by the caller rather than read via AccountInfoDouble()    |
//| internally, so IsTriggered() is testable with plain numbers.       |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Config.mqh"

class CEmergencyStop
{
private:
   double m_peakEquity;

public:
   CEmergencyStop() { m_peakEquity = 0.0; }

   /// Call once from OnInit() with the starting equity.
   void Init(double startingEquity)
   {
      m_peakEquity = startingEquity;
   }

   double PeakEquity() const { return m_peakEquity; }

   /// Updates the peak if a new high is seen, then checks drawdown from
   /// that peak against InpEmergencyMaxDrawdownPercent.
   bool IsTriggered(double currentEquity)
   {
      if(currentEquity > m_peakEquity)
         m_peakEquity = currentEquity;

      if(m_peakEquity <= 0.0)
         return false; // not initialized / no meaningful peak yet

      double drawdownPercent = (m_peakEquity - currentEquity) / m_peakEquity * 100.0;
      return drawdownPercent >= InpEmergencyMaxDrawdownPercent;
   }
};
//+------------------------------------------------------------------+
