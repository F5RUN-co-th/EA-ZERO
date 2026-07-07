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


PHASE 1 - BATCH 2 (MarketData + Pattern Detector + Tests)
============================================================

CHANGED FILES (already in your Batch 1 commit - review before overwriting)
-----------------------------------------------------------------------------
Core/Config.mqh   <- ADDED two new input groups: "Market Data" (ATR period)
                     and "Pattern Thresholds" (Doji/Marubozu/Hammer ratios).
                     Nothing removed or renamed, safe to overwrite.
EA.mq5            <- Step 4 now uses MarketData (CopyRates wrapper) instead
                     of calling CopyRates() directly. Step 6 now calls the
                     real PatternDetector.Scan() and logs every signal found.
                     Steps 7-11 are still TODO (Classification/Strategy/
                     Risk/Trade - next batches).

NEW FILES
-----------
Data/MarketData.mqh              <- wraps CopyRates() + ATR indicator
Pattern/SinglePattern.mqh        <- Hammer, Shooting Star, Doji,
                                     Bullish/Bearish Marubozu, Spinning Top
Pattern/DoublePattern.mqh        <- Bullish Engulfing, Bearish Engulfing
Pattern/PatternDetector.mqh      <- implements IPatternDetector, aggregates
                                     Single + Double pattern scans
Tests/TestFramework.mqh          <- shared Assert/AlmostEqual/MakeCandle
                                     helpers (Test_CandleUtils.mq5 was
                                     refactored to use these instead of
                                     duplicating them)
Tests/Test_PatternDetector.mq5   <- feeds known-answer candle fixtures
                                     through SinglePattern, DoublePattern,
                                     and the full Scan() pipeline

SCOPE NOTE (intentional, not a bug)
--------------------------------------
Only 8 patterns are implemented so far: Hammer, Shooting Star, Doji,
Bullish Marubozu, Bearish Marubozu, Spinning Top, Bullish Engulfing,
Bearish Engulfing.

Hanging Man and Inverted Hammer are NOT detected yet - they are the exact
same shape as Hammer/Shooting Star, and telling them apart needs to know
the prior trend direction. That's Market Structure info, which is a
Phase 2 Feature (see the IFeature comment in Core/Interfaces.mqh) -
building it now would be getting ahead of what's actually needed for v1.

Harami, Piercing Line, Dark Cloud, Tweezer, and all three Triple-candle
patterns (Morning/Evening Star, Three Soldiers/Crows) are Batch 3.

HOW TO TEST THIS BATCH
--------------------------
1. Compile EA.mq5 (F7) - should still be 0 errors, 0 warnings.
2. In MetaEditor, open Tests/Test_CandleUtils.mq5 and Tests/Test_PatternDetector.mq5,
   compile each (F7).
3. In MT5 terminal: Navigator > Scripts > drag each test script onto any
   chart. Check the "Experts" tab - every line should say [PASS]. If you
   see a [FAIL] line, paste the exact output back into the chat.
4. Optionally, attach the EA itself to a chart and watch the Experts tab -
   on each new bar you should see a "Pattern scan found N signal(s)" line,
   with details for each one. No trades should open yet.

WHAT'S NEXT (Phase 1, batch 3)
---------------------------------
- Remaining Double patterns: Harami, Piercing Line, Dark Cloud, Tweezer
- Triple patterns: Morning Star, Evening Star, Three Soldiers, Three Crows
- Classification/PatternClassifier.mqh (turns signals into bull/bear/neutral scores)


PHASE 1 - BATCH 3 (Remaining Patterns + Classifier)
=======================================================

CHANGED FILES (already in your Batch 1/2 commits - review before overwriting)
----------------------------------------------------------------------------------
Core/Config.mqh          <- ADDED: 3 new pattern thresholds (Tweezer/Star/Soldiers)
                             and a full "Pattern Weights" group (18 inputs, one per
                             implemented pattern type). Nothing removed/renamed.
Pattern/DoublePattern.mqh <- ADDED: DetectBullishHarami, DetectBearishHarami,
                             DetectPiercingLine, DetectDarkCloudCover,
                             DetectTweezerTop, DetectTweezerBottom.
                             Existing Engulfing functions unchanged.
Pattern/PatternDetector.mqh <- Scan() now also runs the 6 new double-pattern
                             checks per bar pair, plus a new triple-candle loop.
EA.mq5                   <- Step 7 now calls PatternClassifier.Score() and logs
                             bull/bear/neutral scores. Steps 8-11 still TODO.
Tests/Test_PatternDetector.mq5 <- 10 new fixtures added (one per new pattern,
                             plus a cross-check that Piercing Line does NOT also
                             register as a full Bullish Engulfing).

NEW FILES
-----------
Pattern/TriplePattern.mqh          <- Morning Star, Evening Star,
                                       Three White Soldiers, Three Black Crows
Classification/PatternClassifier.mqh <- implements IScorer, aggregates signals
                                       into bull/bear/neutral using per-type
                                       weight inputs
Tests/Test_PatternClassifier.mq5   <- verifies weight lookup + aggregation math

DESIGN NOTE: detector vs classifier responsibility
------------------------------------------------------
Every pattern detector (Single/Double/Triple) assigns a flat 1.0 to its
bullish/bearish/neutral score - a plain "this direction, yes/no" flag.
None of them decide that a Morning Star matters more than a Hammer.
That judgement now lives entirely in PatternClassifier, via one `input`
weight per pattern type (Core/Config.mqh, "Pattern Weights" group) - so
the Strategy Tester's optimizer can tune which patterns actually matter
for a given symbol/timeframe, without touching any detector code.

SCOPE NOTE (intentional, not a bug)
--------------------------------------
Morning/Evening Star use a relaxed (no-strict-gap) definition - see the
comment at the top of Pattern/TriplePattern.mqh for why: Forex rarely
gaps between candles the way stock exchanges do, so requiring a textbook
gap would make these patterns almost never fire on Forex charts.

Hanging Man and Inverted Hammer are still not detected (same reasoning
as Batch 2 - they need trend context, which is a Phase 2 Feature).

All 18 candlestick patterns that CAN be identified without trend context
are now implemented (14 from Batch 2 + Batch 3's Harami/Piercing/Dark
Cloud/Tweezer/Star/Soldiers/Crows). Classification -> Decision -> Risk ->
Trade is what's left before this is a complete v1.

HOW TO TEST THIS BATCH
--------------------------
1. Compile EA.mq5 (F7) - should still be 0 errors, 0 warnings.
2. Compile and run Tests/Test_PatternDetector.mq5 and
   Tests/Test_PatternClassifier.mq5 as Scripts (same process as Batch 2).
   Every line in the Experts tab should say [PASS].
3. Attach the EA to a chart - on each new bar you should now also see a
   "Classifier scores | bull=... bear=... neutral=..." line after the
   pattern scan line. Still no trades open.

WHAT'S NEXT (Phase 1, batch 4)
---------------------------------
- Strategy/DecisionEngine.mqh (turns scores into DIRECTION_BUY/SELL/NONE)
- Strategy/StateMachine.mqh (FLAT/IN_TRADE/COOLDOWN/RECOVERY)
- This is the point where the EA can theoretically decide something -
  still without opening real trades until Risk/Trade land in Batch 5.
