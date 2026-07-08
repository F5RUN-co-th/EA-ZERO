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


PHASE 1 - BATCH 4 (DecisionEngine + StateMachine)
=====================================================

NEW FILES
-----------
Strategy/StateMachine.mqh   <- FLAT/IN_TRADE/COOLDOWN/RECOVERY. Sync(bool
                               hasPosition) takes the position status as a
                               parameter instead of querying the broker
                               itself - EA.mq5 checks the broker (via a
                               small HasOpenPosition() helper) and passes
                               the result in. This makes the state machine
                               100% pure/testable with plain booleans.
Strategy/DecisionEngine.mqh <- Converts bull/bear/neutral scores into a
                               TradeDirection. A direction only wins if it
                               clears InpMinScoreThreshold AND beats the
                               opposite side by InpDominanceRatio - this
                               rejects both weak signals and near-ties.
Tests/Test_StateMachine.mq5   <- drives Sync()/Transition() with plain
                               true/false values, no broker needed
Tests/Test_DecisionEngine.mq5 <- checks BUY/SELL/NONE against the default
                               InpMinScoreThreshold/InpDominanceRatio

CHANGED FILES
---------------
EA.mq5  <- Added HasOpenPosition() helper (checks PositionsTotal/
           PositionGetTicket filtered by symbol+magic). Wired
           g_stateMachine.Sync(HasOpenPosition()) every tick,
           g_stateMachine.Transition() + COOLDOWN check at the top of the
           new-bar block, and g_decisionEngine.Decide() at step 8. Still
           no trade is opened - Decision is logged, not executed.

CAUGHT DURING THIS BATCH (worth knowing about)
--------------------------------------------------
Early in this batch, two input groups ("State Machine" with
InpMaxConsecutiveLosses, and a second "Decision Engine" group with
InpMinScoreThreshold/InpMinScoreEdge) were drafted assuming a different
StateMachine design than what actually existed in the project - which
would have DUPLICATE-DECLARED InpMinScoreThreshold and produced a
compile error. Caught and removed before packaging. If you ever see a
"variable already defined" error after pulling a batch, that class of
mistake - two different input groups declaring the same name - is the
first thing to check.

DESIGN NOTE: RECOVERY is not yet auto-triggered
----------------------------------------------------
StateMachine exposes EnterRecovery()/ExitRecovery(), but nothing calls
them yet - there's no real trade-result history to base a "consecutive
losses" decision on until Trade/TradeManager.mqh exists. Batch 5's
RiskManager will call these once it has genuine win/loss data from
TradeManager, rather than StateMachine reaching into deal history itself
(keeps state-tracking and P&L-computation as separate responsibilities).

HOW TO TEST THIS BATCH
--------------------------
1. Compile EA.mq5 (F7) - should still be 0 errors, 0 warnings.
2. Compile and run Tests/Test_StateMachine.mq5 and
   Tests/Test_DecisionEngine.mq5 as Scripts. Every line in the Experts
   tab should say [PASS].
3. Attach the EA to a chart - on each new bar you should now see a
   "Decision: DIRECTION_... | SystemState=..." line after the classifier
   scores line. Still no trades open (that's Batch 5).

WHAT'S NEXT (Phase 1, batch 5)
---------------------------------
- Risk/RiskManager.mqh, Risk/ExecutionFilter.mqh, Risk/TradeLock.mqh,
  Risk/EmergencyStop.mqh
- Trade/TradeManager.mqh (implements ITradeExecutor)
- This is the batch where the EA opens its first real trade - test on a
  demo account only.


PHASE 1 - BATCH 5 (Risk + Trade) - EA NOW OPENS REAL ORDERS
================================================================

*** TEST THIS BATCH ON A DEMO ACCOUNT ONLY ***
Everything before this batch only computed numbers and logged them.
As of this batch, EA.mq5 calls CTradeManager.OpenBuy()/OpenSell(), which
sends real orders to whatever account the EA is attached to. Attach to
a demo chart first. Do not attach to a live account until you've watched
it trade correctly on demo for a while.

NEW FILES
-----------
Risk/ExecutionFilter.mqh <- CheckSpread/CheckSession/TickCheck/MarketCheck.
                            Same "caller passes in terminal values" pattern
                            as StateMachine - spread and hour are read by
                            EA.mq5 and passed in, so the filter logic
                            itself is unit-testable.
Risk/TradeLock.mqh       <- Blocked(barTime, openPositionsCount). The
                            one-trade-per-bar check is structurally
                            redundant given the current IsNewBar() gating
                            (documented in the file) but kept as cheap
                            defense-in-depth. The max-open-positions check
                            is NOT redundant - it's what actually stops a
                            second entry while IN_TRADE.
Risk/EmergencyStop.mqh   <- Tracks peak equity since EA start, triggers
                            when drawdown from that peak reaches
                            InpEmergencyMaxDrawdownPercent (default 20%).
                            Checked every tick, before anything else.
Risk/RiskManager.mqh     <- SL/TP distance from ATR, lot sizing from
                            risk %, RECOVERY-aware (multiplies lot by
                            InpRecoveryLotMultiplier). Validate() is the
                            single entry point EA.mq5 calls - it also
                            vetoes the trade if ATR isn't ready yet.
Trade/TradeManager.mqh   <- implements ITradeExecutor using MT5's
                            standard CTrade class. The only module that
                            actually sends orders. NOT unit-tested (can't
                            be, without a live/demo connection) - verify
                            this one on a demo chart instead.
Tests/Test_ExecutionFilter.mq5
Tests/Test_TradeLock.mq5
Tests/Test_EmergencyStop.mq5
Tests/Test_RiskManager.mq5
   (4 new test scripts - all pure logic, no broker connection needed)

CHANGED FILES
---------------
Core/Config.mqh <- ADDED InpRecoveryLotMultiplier (Risk group) and
                   InpEmergencyMaxDrawdownPercent (Emergency group).
                   Nothing removed/renamed.
EA.mq5          <- Full pipeline now wired: Emergency check (step 0),
                   TradeLock + StateMachine guards (steps 1-2),
                   ExecutionFilter tick/market checks (steps 3+5),
                   RiskManager.Validate() (step 9), and
                   TradeManager.OpenBuy()/OpenSell() (step 10). Every
                   TODO from the original flow comment is now [DONE].
                   Renamed HasOpenPosition() -> CountOpenPositions()
                   (returns int) since TradeLock needs a count, not
                   just a bool.

HOW TO TEST THIS BATCH
--------------------------
1. Compile EA.mq5 (F7) - should still be 0 errors, 0 warnings.
2. Compile and run all 4 new test scripts (Test_ExecutionFilter,
   Test_TradeLock, Test_EmergencyStop, Test_RiskManager). Every line
   in the Experts tab should say [PASS].
3. Attach the EA to a chart ON A DEMO ACCOUNT. Watch the Experts tab -
   you should see the same Pattern/Classifier/Decision lines as before,
   and now, when a decision clears the RiskManager checks, a
   "Trade OPENED | dir=... lot=... sl=... tp=..." line, followed by a
   real position appearing in the Trade tab.
4. Manually close that demo position and confirm the next new bar logs
   "state is COOLDOWN" for InpCooldownBars bars before evaluating
   signals again.

WHAT'S NEXT (Phase 1, batch 6 - final)
------------------------------------------
- Tests/Test_EndToEndPatternPipeline.mq5 (the acceptance/integration
  test agreed on earlier: feeds a full OHLC fixture through
  MarketData -> PatternDetector -> PatternClassifier -> DecisionEngine
  and checks the final decision, stopping before TradeManager.Execute())
- A final pass over all Batch 1-5 README notes to confirm nothing was
  left as a dangling TODO before calling Phase 1 "done".
