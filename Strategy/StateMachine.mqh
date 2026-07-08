//+------------------------------------------------------------------+
//| StateMachine.mqh                                                   |
//| Tracks SystemState (FLAT/IN_TRADE/COOLDOWN/RECOVERY).              |
//|                                                                    |
//| Deliberately does NOT call PositionsTotal()/PositionGetTicket()    |
//| itself - Sync() takes hasPosition as a parameter instead. The      |
//| caller (EA.mq5) is responsible for checking the broker/terminal.   |
//| This keeps the state-transition logic itself fully unit-testable   |
//| with plain booleans (see Tests/Test_StateMachine.mq5) - the same   |
//| "push side-effecting API calls to the edge" pattern already used   |
//| by Data/MarketData.mqh and Pattern/PatternDetector.mqh.            |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Types.mqh"
#include "../Core/Config.mqh"

class CStateMachine
{
private:
   SystemState m_state;
   int         m_cooldownBarsRemaining;
   bool        m_hadPositionLastSync;

public:
   CStateMachine()
   {
      m_state                 = STATE_FLAT;
      m_cooldownBarsRemaining = 0;
      m_hadPositionLastSync   = false;
   }

   SystemState CurrentState() const { return m_state; }

   /// Call every tick (not gated by new-bar). Detects a position opening
   /// or closing even if TradeManager didn't directly report it - e.g.
   /// SL/TP hit, or a manual close/open by the person watching the chart.
   /// @param hasPosition Whether a live position currently exists for
   ///                     this EA/symbol (checked by the caller).
   void Sync(bool hasPosition)
   {
      if(hasPosition && !m_hadPositionLastSync)
      {
         m_state = STATE_IN_TRADE;
      }
      else if(!hasPosition && m_hadPositionLastSync)
      {
         m_state                 = STATE_COOLDOWN;
         m_cooldownBarsRemaining = InpCooldownBars;
      }

      m_hadPositionLastSync = hasPosition;
   }

   /// Call once per new bar, after Sync() and before evaluating any new
   /// signal. Counts down COOLDOWN and releases back to FLAT once
   /// InpCooldownBars new bars have passed since the position closed.
   void Transition()
   {
      if(m_state == STATE_COOLDOWN)
      {
         m_cooldownBarsRemaining--;
         if(m_cooldownBarsRemaining <= 0)
            m_state = STATE_FLAT;
      }
   }

   /// Intended to be called by RiskManager once drawdown-based recovery
   /// logic exists (Batch 5) - there's no trade history to base that
   /// decision on until Trade/TradeManager.mqh lands, so nothing calls
   /// this yet. Exposed now so RiskManager can call it without another
   /// StateMachine change later.
   void EnterRecovery()
   {
      if(m_state == STATE_FLAT)
         m_state = STATE_RECOVERY;
   }

   /// Called by RiskManager once equity/drawdown has recovered enough
   /// to resume full-size trading.
   void ExitRecovery()
   {
      if(m_state == STATE_RECOVERY)
         m_state = STATE_FLAT;
   }
};
//+------------------------------------------------------------------+
