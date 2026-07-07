//+------------------------------------------------------------------+
//| MarketData.mqh                                                     |
//| Wraps CopyRates/ATR access behind one class so:                    |
//|  - Detectors never call CopyRates() directly (low coupling)        |
//|  - Tests can inject a fixed set of bars via LoadFromArray()        |
//|    instead of needing a live chart (deterministic, backtestable)   |
//+------------------------------------------------------------------+
#property strict

class CMarketData
{
private:
   string          m_symbol;
   ENUM_TIMEFRAMES m_timeframe;
   int             m_atrHandle;
   MqlRates        m_rates[];

public:
   CMarketData(string symbol, ENUM_TIMEFRAMES timeframe, int atrPeriod = 14)
   {
      m_symbol    = symbol;
      m_timeframe = timeframe;
      m_atrHandle = iATR(m_symbol, m_timeframe, atrPeriod);
      ArraySetAsSeries(m_rates, true);
   }

   ~CMarketData()
   {
      if(m_atrHandle != INVALID_HANDLE)
         IndicatorRelease(m_atrHandle);
   }

   /// Loads the latest `count` bars from the live chart.
   /// @return true if at least one bar was copied.
   bool LoadFromChart(int count = 50)
   {
      int copied = CopyRates(m_symbol, m_timeframe, 0, count, m_rates);
      return (copied > 0);
   }

   /// Test/backtest hook: inject a fixed set of bars instead of reading
   /// from the live chart. index 0 must be the most recent bar (as-series).
   void LoadFromArray(const MqlRates &source[])
   {
      int n = ArraySize(source);
      ArrayResize(m_rates, n);
      for(int i = 0; i < n; i++)
         m_rates[i] = source[i];
   }

   /// Copies the currently loaded bars into dest[]. Returns bar count.
   int GetRates(MqlRates &dest[]) const
   {
      int n = ArraySize(m_rates);
      ArrayResize(dest, n);
      for(int i = 0; i < n; i++)
         dest[i] = m_rates[i];
      return n;
   }

   int Count() const
   {
      return ArraySize(m_rates);
   }

   /// Current ATR value at the given shift (default: last closed bar).
   /// Returns 0.0 if the ATR handle/data is not ready yet.
   double GetATR(int shift = 1)
   {
      if(m_atrHandle == INVALID_HANDLE)
         return 0.0;

      double buffer[];
      ArraySetAsSeries(buffer, true);

      if(CopyBuffer(m_atrHandle, 0, shift, 1, buffer) <= 0)
         return 0.0;

      return buffer[0];
   }
};
//+------------------------------------------------------------------+
