//+------------------------------------------------------------------+
//|                                                          EA.mq5   |
//| Candlestick Pattern EA - Phase 1 walking skeleton                 |
//|                                                                    |
//| This file compiles and runs end-to-end on its own. It wires up    |
//| Config + Logger + new-bar gating + CandleUtils so the foundation   |
//| is verified before Pattern/Risk/Trade modules are added on top.   |
//| Each TODO marks where the next Phase 1 module plugs in, following |
//| the execution flow agreed for this EA:                            |
//|                                                                    |
//|   OnTick()                                                        |
//|     |-- EmergencyStop check            (every tick)               |
//|     |-- StateMachine.Sync()            (every tick)               |
//|     |-- ManageOpenPositions()          (every tick)               |
//|     '-- if IsNewBar():                                            |
//|          1. TradeLock.Blocked check                               |
//|          2. State == COOLDOWN check                               |
//|          3. ExecutionFilter.TickCheck()   (cheap, no history)     |
//|          4. MarketData.Update()                                   |
//|          5. ExecutionFilter.MarketCheck() (needs ATR/history)     |
//|          6. PatternDetector.Scan()                                |
//|          7. PatternClassifier.Score()                             |
//|          8. DecisionEngine.Decide()                                |
//|          9. RiskManager.Validate()                                |
//|         10. TradeManager.Execute()                                |
//|         11. StateMachine.Transition()                             |
//+------------------------------------------------------------------+
#property copyright "Phase 1"
#property version   "1.00"
#property strict

#include "Core/Types.mqh"
#include "Core/Interfaces.mqh"
#include "Core/Config.mqh"
#include "Core/Logger.mqh"
#include "Utils/CandleUtils.mqh"

CLogger  g_logger("PatternEA");
datetime g_lastBarTime = 0;

//+------------------------------------------------------------------+
//| Returns true exactly once per new closed bar.                     |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, _Period, 0);

   if(currentBarTime != g_lastBarTime)
   {
      g_lastBarTime = currentBarTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   g_lastBarTime = 0;

   g_logger.Info(StringFormat(
      "EA initialized | ConfigVersion=%d | MagicNumber=%d | Symbol=%s | TF=%s",
      InpConfigVersion, (int)GetMagicNumber(), _Symbol, EnumToString(_Period)));

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   g_logger.Info("EA deinitialized | reason=" + IntegerToString(reason));
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- 0. Emergency guard: every tick, before anything else ---
   // TODO (Risk/EmergencyStop.mqh):
   //   if(InpEnableEmergencyStop && emergencyStop.Triggered())
   //   {
   //      tradeManager.CloseAll();
   //      return;
   //   }

   //--- Tick-level position management (every tick, not gated by new bar) ---
   // TODO (Strategy/StateMachine.mqh): stateMachine.Sync();
   // TODO (Trade/TradeManager.mqh):    tradeManager.ManageOpenPositions();

   if(!IsNewBar())
      return;

   g_logger.Debug("New bar: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES));

   //--- 1-2. State / lock guards ---
   // TODO (Risk/TradeLock.mqh):      if(tradeLock.Blocked()) return;
   // TODO (Strategy/StateMachine):   if(stateMachine.CurrentState() == STATE_COOLDOWN) return;

   //--- 3. Cheap tick-level checks before touching price history ---
   // TODO (Risk/ExecutionFilter.mqh): if(!executionFilter.TickCheck()) return;

   //--- 4. Load market data ---
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, _Period, 0, 50, rates);

   if(copied <= 0)
   {
      g_logger.Warn("CopyRates failed, skipping this bar");
      return;
   }

   //--- 5. Market-level checks (needs price history, e.g. ATR) ---
   // TODO (Risk/ExecutionFilter.mqh): if(!executionFilter.MarketCheck(rates)) return;

   //--- Sanity check on the foundation: CandleUtils working on real data ---
   double lastBody = CCandleUtils::BodySize(rates[1]);
   bool   lastBull = CCandleUtils::IsBullish(rates[1]);
   g_logger.Debug(StringFormat("Last closed bar | body=%.5f | bullish=%s",
                                lastBody, lastBull ? "true" : "false"));

   //--- 6-11. Pattern -> Score -> Decision -> Risk -> Trade -> State ---
   // TODO (Pattern/PatternDetector.mqh):           detector.Scan(rates, signals);
   // TODO (Classification/PatternClassifier.mqh):  classifier.Score(signals, bull, bear, neutral);
   // TODO (Strategy/DecisionEngine.mqh):            direction = decisionEngine.Decide(bull, bear, neutral);
   // TODO (Risk/RiskManager.mqh):                   riskManager.Validate(direction, stateMachine.CurrentState());
   // TODO (Trade/TradeManager.mqh):                 tradeManager.Execute(direction, lot, sl, tp);
   // TODO (Strategy/StateMachine.mqh):              stateMachine.Transition();
}
//+------------------------------------------------------------------+
