PHASE 1 - BATCH 1 (Foundation + Walking Skeleton)
==================================================

WHAT'S IN THIS BATCH
---------------------
EA.mq5                  <- walking skeleton, compiles and runs on its own
Core/Types.mqh          <- PatternType, PatternSignal, TradeDirection, SystemState
Core/Interfaces.mqh     <- IPatternDetector, IFeature, IScorer, IDecisionEngine, ITradeExecutor
Core/Config.mqh         <- all input parameters + GetMagicNumber()
Core/Logger.mqh         <- CLogger (Debug/Info/Warn/Error)
Utils/CandleUtils.mqh   <- BodySize, UpperShadow, LowerShadow, Range, IsBullish,
                            IsBearish, MidPoint, ATRNormalize

HOW TO INSTALL / COMPILE
--------------------------
1. Unzip this into: <MT5 Data Folder>/MQL5/Experts/PatternEA/
   (File > Open Data Folder in MT5 to find the path)
   You should end up with:
     MQL5/Experts/PatternEA/EA.mq5
     MQL5/Experts/PatternEA/Core/...
     MQL5/Experts/PatternEA/Utils/...
2. Open EA.mq5 in MetaEditor.
3. Press F7 (Compile). Expect 0 errors, 0 warnings.
4. Drag the compiled EA onto any chart. Open the "Experts" tab in the
   MT5 terminal - you should see one INFO line on init, and one DEBUG
   line per new closed bar showing the last candle's body size.
   (Debug lines only show if the terminal's log level is set to show
   them - if you don't see them, that's just verbosity, not an error.)

WHAT IT DOES RIGHT NOW
------------------------
- Logs startup info (config version, magic number, symbol, timeframe)
- Detects new bars correctly (IsNewBar guard)
- Loads price history via CopyRates
- Runs CandleUtils on real data as a sanity check
- Does NOT open any trades yet - that's intentional for this batch

WHAT'S NEXT (Phase 1, batch 2)
---------------------------------
- Data/MarketData.mqh
- Pattern/PatternDetector.mqh + Single/Double/TriplePattern.mqh
- Tests/Test_CandleUtils.mq5 (mock candle fixtures, no chart needed)

IF COMPILATION FAILS
-----------------------
Please paste the exact error/warning text and line number back into
the chat - these will be fixed immediately before moving to the next
batch, per the "build one module, compile, then continue" approach.
