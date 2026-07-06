//+------------------------------------------------------------------+
//| Interfaces.mqh                                                    |
//| Abstract contracts for the Pattern EA modules. Keeping these as   |
//| thin interfaces lets each module be mocked and unit-tested        |
//| independently (see /Tests).                                       |
//+------------------------------------------------------------------+
#property strict

#include "Types.mqh"

//+------------------------------------------------------------------+
//| Detects candlestick patterns from raw price data.                 |
//+------------------------------------------------------------------+
class IPatternDetector
{
public:
   virtual ~IPatternDetector() {}

   /// Scan a series of bars and append any detected patterns to signals[].
   /// @param rates    Price history, index 0 = most recent bar (as-series).
   /// @param signals  Output array of detected pattern signals.
   virtual void Scan(const MqlRates &rates[], PatternSignal &signals[]) = 0;
};

//+------------------------------------------------------------------+
//| Marker interface reserved for Phase 2 feature modules             |
//| (Market Structure, FVG, Order Block, ATR/Volatility, Session...). |
//|                                                                    |
//| NOTE: intentionally left without a fixed method contract. Each    |
//| Phase 2 feature returns a different shape of data - Market        |
//| Structure needs an enum (Uptrend/Downtrend/Range), FVG needs a    |
//| price zone struct, Session needs a bool, ATR needs a double.      |
//| Fixing something like Value()/Weight() now would force one shape  |
//| onto features that don't exist yet (YAGNI). The real contract     |
//| gets defined from the first concrete Phase 2 implementation.      |
//+------------------------------------------------------------------+
class IFeature
{
public:
   virtual ~IFeature() {}
};

//+------------------------------------------------------------------+
//| Converts raw pattern signals into aggregated scores.               |
//+------------------------------------------------------------------+
class IScorer
{
public:
   virtual ~IScorer() {}

   /// Aggregate pattern signals into bullish / bearish / neutral scores.
   virtual void Score(const PatternSignal &signals[],
                       double &bullishScore,
                       double &bearishScore,
                       double &neutralScore) = 0;
};

//+------------------------------------------------------------------+
//| Turns aggregated scores into a trade decision.                    |
//+------------------------------------------------------------------+
class IDecisionEngine
{
public:
   virtual ~IDecisionEngine() {}

   virtual TradeDirection Decide(double bullishScore,
                                  double bearishScore,
                                  double neutralScore) = 0;
};

//+------------------------------------------------------------------+
//| Executes trade actions on the broker / terminal.                  |
//+------------------------------------------------------------------+
class ITradeExecutor
{
public:
   virtual ~ITradeExecutor() {}

   virtual bool OpenBuy(double lot, double sl, double tp, string comment)  = 0;
   virtual bool OpenSell(double lot, double sl, double tp, string comment) = 0;
   virtual bool ModifyPosition(ulong ticket, double sl, double tp)         = 0;
   virtual bool CloseAll()                                                 = 0;
};
//+------------------------------------------------------------------+
