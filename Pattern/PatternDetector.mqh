//+------------------------------------------------------------------+
//| PatternDetector.mqh                                               |
//| Implements IPatternDetector. Aggregates every Single/Double/      |
//| Triple pattern detector into one Scan() call, so EA.mq5 only ever |
//| talks to this one class - not to each shape detector directly.    |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Interfaces.mqh"
#include "SinglePattern.mqh"
#include "DoublePattern.mqh"
#include "TriplePattern.mqh"

class CPatternDetector : public IPatternDetector
{
public:
   /// Scans rates[] (as-series, index 0 = still-forming bar) for every
   /// known pattern shape and appends results to signals[].
   /// Bar shift 0 is skipped since it hasn't closed yet.
   virtual void Scan(const MqlRates &rates[], PatternSignal &signals[])
   {
      ArrayResize(signals, 0);

      int total = ArraySize(rates);
      if(total < 1)
         return;

      //--- Single-candle shapes: every closed bar
      for(int i = 1; i < total; i++)
      {
         PatternSignal s;
         if(CSinglePattern::Detect(rates[i], s))
         {
            s.barShift = i;
            Append(signals, s);
         }
      }

      //--- Double-candle shapes: curr = rates[i] (newer), prev = rates[i+1] (older)
      for(int i = 1; i < total - 1; i++)
      {
         MqlRates curr = rates[i];
         MqlRates prev = rates[i + 1];

         PatternSignal s;

         if(CDoublePattern::DetectBullishEngulfing(prev, curr, s)) { s.barShift = i; Append(signals, s); }
         if(CDoublePattern::DetectBearishEngulfing(prev, curr, s)) { s.barShift = i; Append(signals, s); }
         if(CDoublePattern::DetectBullishHarami(prev, curr, s))    { s.barShift = i; Append(signals, s); }
         if(CDoublePattern::DetectBearishHarami(prev, curr, s))    { s.barShift = i; Append(signals, s); }
         if(CDoublePattern::DetectPiercingLine(prev, curr, s))     { s.barShift = i; Append(signals, s); }
         if(CDoublePattern::DetectDarkCloudCover(prev, curr, s))   { s.barShift = i; Append(signals, s); }
         if(CDoublePattern::DetectTweezerTop(prev, curr, s))       { s.barShift = i; Append(signals, s); }
         if(CDoublePattern::DetectTweezerBottom(prev, curr, s))    { s.barShift = i; Append(signals, s); }
      }

      //--- Triple-candle shapes: c3 = rates[i] (newest), c2 = rates[i+1], c1 = rates[i+2] (oldest)
      for(int i = 1; i < total - 2; i++)
      {
         MqlRates c3 = rates[i];
         MqlRates c2 = rates[i + 1];
         MqlRates c1 = rates[i + 2];

         PatternSignal s;

         if(CTriplePattern::DetectMorningStar(c1, c2, c3, s))         { s.barShift = i; Append(signals, s); }
         if(CTriplePattern::DetectEveningStar(c1, c2, c3, s))         { s.barShift = i; Append(signals, s); }
         if(CTriplePattern::DetectThreeWhiteSoldiers(c1, c2, c3, s))  { s.barShift = i; Append(signals, s); }
         if(CTriplePattern::DetectThreeBlackCrows(c1, c2, c3, s))     { s.barShift = i; Append(signals, s); }
      }
   }

private:
   static void Append(PatternSignal &signals[], const PatternSignal &s)
   {
      int n = ArraySize(signals);
      ArrayResize(signals, n + 1);
      signals[n] = s;
   }
};
//+------------------------------------------------------------------+
