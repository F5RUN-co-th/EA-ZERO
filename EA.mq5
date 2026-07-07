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
#include "Data/MarketData.mqh"
#include "Pattern/PatternDetector.mqh"

CLogger          g_logger("PatternEA");
CMarketData      g_marketData(_Symbol, _Period, InpATRPeriod);
CPatternDetector g_detector;
datetime         g_lastBarTime = 0;

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

   //--- 7-11. Score -> Decision -> Risk -> Trade -> State (next batches) ---
   // TODO (Classification/PatternClassifier.mqh):  classifier.Score(signals, bull, bear, neutral);
   // TODO (Strategy/DecisionEngine.mqh):            direction = decisionEngine.Decide(bull, bear, neutral);
   // TODO (Risk/RiskManager.mqh):                   riskManager.Validate(direction, stateMachine.CurrentState());
   // TODO (Trade/TradeManager.mqh):                 tradeManager.Execute(direction, lot, sl, tp);
   // TODO (Strategy/StateMachine.mqh):              stateMachine.Transition();
}
//+------------------------------------------------------------------+
