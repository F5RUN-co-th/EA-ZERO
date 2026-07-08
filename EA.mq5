//+------------------------------------------------------------------+
//|                                                          EA.mq5   |
//| Candlestick Pattern EA - Phase 1                                   |
//|                                                                    |
//| Full pipeline, following the execution flow agreed for this EA:   |
//|                                                                    |
//|   OnTick()                                                        |
//|     |-- EmergencyStop check            (every tick)  [DONE]      |
//|     |-- StateMachine.Sync()            (every tick)  [DONE]      |
//|     |-- ManageOpenPositions()          (every tick)  [not in     |
//|     |    Phase 1 scope - trailing/breakeven is a post-v1 item]   |
//|     '-- if IsNewBar():                                            |
//|          1. TradeLock.Blocked check              [DONE]          |
//|          2. StateMachine.Transition() +                          |
//|             State == COOLDOWN check              [DONE]          |
//|          3. ExecutionFilter.TickCheck()           [DONE]          |
//|          4. MarketData.Update()                   [DONE]          |
//|          5. ExecutionFilter.MarketCheck()         [DONE]          |
//|          6. PatternDetector.Scan()                [DONE]          |
//|          7. PatternClassifier.Score()              [DONE]          |
//|          8. DecisionEngine.Decide()                [DONE]          |
//|          9. RiskManager.Validate()                 [DONE]          |
//|         10. TradeManager.Execute()                 [DONE]          |
//|         11. StateMachine transitions to IN_TRADE via Sync()       |
//|             on the tick after TradeManager opens a position       |
//|                                                                    |
//| THIS IS THE BATCH WHERE THE EA OPENS ITS FIRST REAL ORDER.        |
//| Test on a DEMO account only - see the Batch 5 section of          |
//| README.txt before attaching this to any live-money chart.         |
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
#include "Risk/EmergencyStop.mqh"
#include "Risk/ExecutionFilter.mqh"
#include "Risk/TradeLock.mqh"
#include "Risk/RiskManager.mqh"
#include "Trade/TradeManager.mqh"

CLogger            g_logger("PatternEA");
CMarketData        g_marketData(_Symbol, _Period, InpATRPeriod);
CPatternDetector   g_detector;
CPatternClassifier g_classifier;
CStateMachine      g_stateMachine;
CDecisionEngine    g_decisionEngine;
CEmergencyStop     g_emergencyStop;
CExecutionFilter   g_executionFilter;
CTradeLock         g_tradeLock;
CRiskManager       g_riskManager;
CTradeManager      g_tradeManager;
datetime           g_lastBarTime = 0;

//+------------------------------------------------------------------+
//| Counts live positions belonging to this EA on this symbol. Lives   |
//| here (not inside StateMachine/TradeLock) so those classes never    |
//| touch the broker API directly - see the design note at the top of  |
//| Strategy/StateMachine.mqh.                                         |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
   int count = 0;
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
         count++;
   }
   return count;
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
   g_emergencyStop.Init(AccountInfoDouble(ACCOUNT_EQUITY));

   g_logger.Info(StringFormat(
      "EA initialized | ConfigVersion=%d | MagicNumber=%d | Symbol=%s | TF=%s | StartEquity=%.2f",
      InpConfigVersion, (int)GetMagicNumber(), _Symbol, EnumToString(_Period),
      g_emergencyStop.PeakEquity()));

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
   if(InpEnableEmergencyStop && g_emergencyStop.IsTriggered(AccountInfoDouble(ACCOUNT_EQUITY)))
   {
      g_logger.Error(StringFormat("EMERGENCY STOP triggered | equity=%.2f peak=%.2f",
                                   AccountInfoDouble(ACCOUNT_EQUITY), g_emergencyStop.PeakEquity()));
      g_tradeManager.CloseAll();
      return;
   }

   //--- Tick-level position management (every tick, not gated by new bar) ---
   int openPositions = CountOpenPositions();
   g_stateMachine.Sync(openPositions > 0);
   // NOTE: trailing stop / breakeven auto-management is a post-v1 item -
   // ITradeExecutor covers open/modify/close, but no auto-trailing logic
   // exists yet. Not part of this project's original Phase 1 scope.

   if(!IsNewBar())
      return;

   g_logger.Debug("New bar: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES));

   //--- 1. TradeLock guard ---
   if(g_tradeLock.Blocked(g_lastBarTime, openPositions))
   {
      g_logger.Debug(StringFormat("Skipping bar: TradeLock blocked (openPositions=%d)", openPositions));
      return;
   }

   //--- 2. State guard ---
   g_stateMachine.Transition(); // counts down COOLDOWN, releases to FLAT if elapsed

   if(g_stateMachine.CurrentState() == STATE_COOLDOWN)
   {
      g_logger.Debug("Skipping bar: state is COOLDOWN");
      return;
   }

   //--- 3. Cheap tick-level checks before touching price history ---
   long currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   if(!g_executionFilter.TickCheck(currentSpread, dt.hour))
   {
      g_logger.Debug(StringFormat("Skipping bar: ExecutionFilter.TickCheck failed (spread=%d hour=%d)",
                                   (int)currentSpread, dt.hour));
      return;
   }

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
   if(!g_executionFilter.MarketCheck(atr))
   {
      g_logger.Debug("Skipping bar: ExecutionFilter.MarketCheck failed");
      return;
   }

   //--- Sanity check on the foundation: CandleUtils + MarketData working on real data ---
   double lastBody = CCandleUtils::BodySize(rates[1]);
   bool   lastBull = CCandleUtils::IsBullish(rates[1]);
   g_logger.Debug(StringFormat("Last closed bar | body=%.5f | bullish=%s | ATR=%.5f",
                                lastBody, lastBull ? "true" : "false", atr));

   //--- 6. Pattern detection ---
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

   //--- 7. Classification ---
   double bullishScore, bearishScore, neutralScore;
   g_classifier.Score(signals, bullishScore, bearishScore, neutralScore);

   g_logger.Debug(StringFormat("Classifier scores | bull=%.2f bear=%.2f neutral=%.2f",
                                bullishScore, bearishScore, neutralScore));

   //--- 8. Decision ---
   TradeDirection direction = g_decisionEngine.Decide(bullishScore, bearishScore, neutralScore);
   g_logger.Debug("Decision: " + EnumToString(direction) +
                   " | SystemState=" + EnumToString(g_stateMachine.CurrentState()));

   //--- 9. Risk (now real) ---
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double equity    = AccountInfoDouble(ACCOUNT_EQUITY);
   double minLot    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   double lot, slDistance, tpDistance;
   bool validated = g_riskManager.Validate(direction, g_stateMachine.CurrentState(), atr,
                                            tickValue, tickSize, equity,
                                            minLot, maxLot, lotStep,
                                            lot, slDistance, tpDistance);

   if(!validated)
   {
      if(direction != DIRECTION_NONE)
         g_logger.Debug("RiskManager.Validate() rejected the trade (see RiskManager.mqh for reasons)");
      return;
   }

   //--- 10. Trade (now real - opens a live/demo order) ---
   double price = (direction == DIRECTION_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                                                : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = (direction == DIRECTION_BUY) ? price - slDistance : price + slDistance;
   double tp = (direction == DIRECTION_BUY) ? price + tpDistance : price - tpDistance;
   string comment = StringFormat("PatternEA_v%d", InpConfigVersion);

   bool opened = (direction == DIRECTION_BUY)
                 ? g_tradeManager.OpenBuy(lot, sl, tp, comment)
                 : g_tradeManager.OpenSell(lot, sl, tp, comment);

   if(opened)
   {
      g_tradeLock.RegisterTradeOpened(g_lastBarTime);
      g_logger.Info(StringFormat("Trade OPENED | dir=%s lot=%.2f sl=%.5f tp=%.5f",
                                  EnumToString(direction), lot, sl, tp));
   }
   else
   {
      g_logger.Error(StringFormat("Trade open FAILED | dir=%s lot=%.2f - check terminal for the broker error",
                                   EnumToString(direction), lot));
   }

   //--- 11. State transitions to IN_TRADE automatically ---
   // No explicit call needed here - g_stateMachine.Sync() (top of OnTick,
   // every tick) will see the new position on the very next tick and move
   // FLAT/RECOVERY -> IN_TRADE by itself.
}
//+------------------------------------------------------------------+
