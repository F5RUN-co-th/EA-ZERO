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
//|     |-- EmergencyStop check            (every tick)  [TODO]      |
//|     |-- StateMachine.Sync()            (every tick)  [DONE]      |
//|     |-- ManageOpenPositions()          (every tick)  [TODO]      |
//|     '-- if IsNewBar():                                            |
//|          1. TradeLock.Blocked check              [TODO]          |
//|          2. StateMachine.Transition() +                          |
//|             State == COOLDOWN check              [DONE]          |
//|          3. ExecutionFilter.TickCheck()           [TODO]          |
//|          4. MarketData.Update()                   [DONE]          |
//|          5. ExecutionFilter.MarketCheck()         [TODO]          |
//|          6. PatternDetector.Scan()                [DONE]          |
//|          7. PatternClassifier.Score()              [DONE]          |
//|          8. DecisionEngine.Decide()                [DONE]          |
//|          9. RiskManager.Validate()                 [TODO]          |
//|         10. TradeManager.Execute()                 [TODO]          |
//|         11. StateMachine transitions to IN_TRADE via Sync()       |
//|             on the tick after TradeManager opens a position       |
//+------------------------------------------------------------------+
#property copyright "Phase 1"
#property version   "1.00"
#property strict

#include "Core/Types.mqh"
#include "Core/Interfaces.mqh"
#include "Core/Config.mqh"
#include "Core/Logger.mqh"
#include "Utils/CandleUtils.mqh"
#include "Data/MarketData.mqh"
#include "Pattern/PatternDetector.mqh"
#include "Classification/PatternClassifier.mqh"
#include "Strategy/StateMachine.mqh"
#include "Strategy/DecisionEngine.mqh"

CLogger            g_logger("PatternEA");
CMarketData        g_marketData(_Symbol, _Period, InpATRPeriod);
CPatternDetector   g_detector;
CPatternClassifier g_classifier;
CStateMachine      g_stateMachine;
CDecisionEngine    g_decisionEngine;
datetime           g_lastBarTime = 0;

//+------------------------------------------------------------------+
//| Checks the broker/terminal for a live position belonging to this   |
//| EA on this symbol. Lives here (not inside StateMachine) so         |
//| StateMachine itself never touches the broker API directly - see    |
//| the comment at the top of Strategy/StateMachine.mqh.               |
//+------------------------------------------------------------------+
bool HasOpenPosition()
{
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;

      if(!PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (long)PositionGetInteger(POSITION_MAGIC) == GetMagicNumber())
         return true;
   }
   return false;
}

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
   g_stateMachine.Sync(HasOpenPosition());
   // TODO (Trade/TradeManager.mqh): tradeManager.ManageOpenPositions();

   if(!IsNewBar())
      return;

   g_logger.Debug("New bar: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES));

   //--- 1-2. State / lock guards ---
   // TODO (Risk/TradeLock.mqh): if(tradeLock.Blocked()) return;

   g_stateMachine.Transition(); // counts down COOLDOWN, releases to FLAT if elapsed

   if(g_stateMachine.CurrentState() == STATE_COOLDOWN)
   {
      g_logger.Debug("Skipping bar: state is COOLDOWN");
      return;
   }

   //--- 3. Cheap tick-level checks before touching price history ---
   // TODO (Risk/ExecutionFilter.mqh): if(!executionFilter.TickCheck()) return;

   //--- 4. Load market data (via wrapper, never CopyRates() directly) ---
   if(!g_marketData.LoadFromChart(50))
   {
      g_logger.Warn("MarketData.LoadFromChart failed, skipping this bar");
      return;
   }

   MqlRates rates[];
   g_marketData.GetRates(rates);

   //--- 5. Market-level checks (needs price history, e.g. ATR) ---
   double atr = g_marketData.GetATR();
   // TODO (Risk/ExecutionFilter.mqh): if(!executionFilter.MarketCheck(rates, atr)) return;

   //--- Sanity check on the foundation: CandleUtils + MarketData working on real data ---
   double lastBody = CCandleUtils::BodySize(rates[1]);
   bool   lastBull = CCandleUtils::IsBullish(rates[1]);
   g_logger.Debug(StringFormat("Last closed bar | body=%.5f | bullish=%s | ATR=%.5f",
                                lastBody, lastBull ? "true" : "false", atr));

   //--- 6. Pattern detection (now real) ---
   PatternSignal signals[];
   g_detector.Scan(rates, signals);

   g_logger.Debug(StringFormat("Pattern scan found %d signal(s)", ArraySize(signals)));
   for(int i = 0; i < ArraySize(signals); i++)
   {
      g_logger.Debug(StringFormat(
         "  -> shift=%d type=%s confidence=%.2f bull=%.2f bear=%.2f neutral=%.2f",
         signals[i].barShift, EnumToString(signals[i].type), signals[i].confidence,
         signals[i].bullishScore, signals[i].bearishScore, signals[i].neutralScore));
   }

   //--- 7. Classification (now real) ---
   double bullishScore, bearishScore, neutralScore;
   g_classifier.Score(signals, bullishScore, bearishScore, neutralScore);

   g_logger.Debug(StringFormat("Classifier scores | bull=%.2f bear=%.2f neutral=%.2f",
                                bullishScore, bearishScore, neutralScore));

   //--- 8. Decision (now real) ---
   TradeDirection direction = g_decisionEngine.Decide(bullishScore, bearishScore, neutralScore);
   g_logger.Debug("Decision: " + EnumToString(direction) +
                   " | SystemState=" + EnumToString(g_stateMachine.CurrentState()));

   //--- 9-11. Risk -> Trade -> State-on-open (Batch 5) ---
   // TODO (Risk/RiskManager.mqh):     riskManager.Validate(direction, g_stateMachine.CurrentState());
   // TODO (Trade/TradeManager.mqh):   tradeManager.Execute(direction, lot, sl, tp);
   // Note: no explicit "StateMachine.Transition() on open" call is needed here -
   // g_stateMachine.Sync() (top of OnTick, every tick) will pick up the new
   // position on the very next tick and move FLAT/RECOVERY -> IN_TRADE itself.
}
//+------------------------------------------------------------------+
