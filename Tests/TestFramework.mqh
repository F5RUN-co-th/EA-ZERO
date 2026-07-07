//+------------------------------------------------------------------+
//| TestFramework.mqh                                                  |
//| Minimal assert/summary/fixture helpers for MQL5 script-based      |
//| tests. MQL5 has no built-in unit test framework, so this fills    |
//| just enough of the gap to verify modules without opening a chart  |
//| or sending a single trade.                                        |
//+------------------------------------------------------------------+
#property strict

int g_testsPass = 0;
int g_testsFail = 0;

void Assert(bool condition, string testName)
{
   if(condition)
   {
      g_testsPass++;
      PrintFormat("  [PASS] %s", testName);
   }
   else
   {
      g_testsFail++;
      PrintFormat("  [FAIL] %s", testName);
   }
}

bool AlmostEqual(double a, double b, double tolerance = 0.00001)
{
   return (MathAbs(a - b) <= tolerance);
}

/// Builds a single MqlRates bar from OHLC values only - convenient for
/// fixtures where volume/spread/tick_volume don't matter for the test.
MqlRates MakeCandle(double o, double h, double l, double c, datetime t = 0)
{
   MqlRates r;
   ZeroMemory(r);
   r.time  = t;
   r.open  = o;
   r.high  = h;
   r.low   = l;
   r.close = c;
   return r;
}

void PrintTestSummary(string suiteName)
{
   PrintFormat("=== %s DONE | PASS=%d FAIL=%d ===", suiteName, g_testsPass, g_testsFail);
   if(g_testsFail > 0)
      Print("!!! ONE OR MORE TESTS FAILED - fix the module before proceeding to the next batch !!!");
}
//+------------------------------------------------------------------+
