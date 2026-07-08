//+------------------------------------------------------------------+
//| Test_StateMachine.mq5                                              |
//| Standalone script - run manually in MT5 (Navigator > Scripts).    |
//| Drives CStateMachine with plain true/false "hasPosition" values -  |
//| no real position or broker connection is needed, since Sync()     |
//| takes hasPosition as a parameter rather than checking the broker   |
//| itself (see the design note in Strategy/StateMachine.mqh).        |
//|                                                                    |
//| Uses the default Config.mqh value InpCooldownBars = 3.             |
//+------------------------------------------------------------------+
#property strict
#property script_show_inputs

#include "TestFramework.mqh"
#include "../Strategy/StateMachine.mqh"

void OnStart()
{
   Print("=== Test_StateMachine START ===");

   //--- Fixture 1: starts FLAT
   {
      CStateMachine sm;
      Assert(sm.CurrentState() == STATE_FLAT, "New StateMachine starts in STATE_FLAT");
   }

   //--- Fixture 2: FLAT -> IN_TRADE when a position appears
   {
      CStateMachine sm;
      sm.Sync(false); // no position yet
      sm.Sync(true);  // position just appeared
      Assert(sm.CurrentState() == STATE_IN_TRADE, "Sync(true) after Sync(false) moves FLAT -> IN_TRADE");
   }

   //--- Fixture 3: IN_TRADE -> COOLDOWN when the position disappears
   {
      CStateMachine sm;
      sm.Sync(true);  // enter IN_TRADE
      sm.Sync(false); // position closed
      Assert(sm.CurrentState() == STATE_COOLDOWN, "Sync(false) after Sync(true) moves IN_TRADE -> COOLDOWN");
   }

   //--- Fixture 4: COOLDOWN only releases to FLAT after InpCooldownBars Transition() calls
   {
      CStateMachine sm;
      sm.Sync(true);
      sm.Sync(false); // now COOLDOWN, counter = InpCooldownBars (default 3)

      for(int i = 0; i < InpCooldownBars - 1; i++)
         sm.Transition();

      Assert(sm.CurrentState() == STATE_COOLDOWN,
             "Still COOLDOWN after InpCooldownBars-1 Transition() calls");

      sm.Transition(); // the final call that should release it

      Assert(sm.CurrentState() == STATE_FLAT,
             "Releases to FLAT after exactly InpCooldownBars Transition() calls");
   }

   //--- Fixture 5: Transition() does nothing when not in COOLDOWN (no crash, no state change)
   {
      CStateMachine sm;
      sm.Transition();
      Assert(sm.CurrentState() == STATE_FLAT, "Transition() on a FLAT machine is a no-op");
   }

   //--- Fixture 6: EnterRecovery()/ExitRecovery() round-trip
   {
      CStateMachine sm;
      sm.EnterRecovery();
      Assert(sm.CurrentState() == STATE_RECOVERY, "EnterRecovery() moves FLAT -> RECOVERY");

      sm.EnterRecovery(); // calling it again should be a harmless no-op
      Assert(sm.CurrentState() == STATE_RECOVERY, "EnterRecovery() is idempotent while already RECOVERY");

      sm.ExitRecovery();
      Assert(sm.CurrentState() == STATE_FLAT, "ExitRecovery() moves RECOVERY -> FLAT");
   }

   //--- Fixture 7: a position appearing overrides COOLDOWN back to IN_TRADE
   //    (reflects reality even if the EA's own cooldown counter hasn't finished -
   //    e.g. a manual trade opened by the person watching the chart)
   {
      CStateMachine sm;
      sm.Sync(true);
      sm.Sync(false); // COOLDOWN
      sm.Sync(true);  // a position exists again
      Assert(sm.CurrentState() == STATE_IN_TRADE, "A reappearing position overrides COOLDOWN back to IN_TRADE");
   }

   PrintTestSummary("Test_StateMachine");
}
//+------------------------------------------------------------------+
