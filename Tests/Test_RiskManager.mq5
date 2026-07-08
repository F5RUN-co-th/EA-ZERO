//+------------------------------------------------------------------+
//| Test_RiskManager.mq5                                              |
//| Standalone script - run manually in MT5 (Navigator > Scripts).    |
//| Feeds plain numbers into RiskManager - no broker connection        |
//| needed, since every terminal-derived value (tick value/size,      |
//| equity, lot limits) is a parameter, not read internally.           |
//|                                                                    |
//| Uses the default Config.mqh values:                                  |
//|   InpStopLossATRMultiplier = 1.5, InpTakeProfitRR = 2.0,             |
//|   InpFixedLot = 0.0, InpRiskPercent = 1.0,                           |
//|   InpRecoveryLotMultiplier = 0.5                                     |
//+------------------------------------------------------------------+
#property strict
#property script_show_inputs

#include "TestFramework.mqh"
#include "../Core/Types.mqh"
#include "../Risk/RiskManager.mqh"

void OnStart()
{
   Print("=== Test_RiskManager START ===");

   CRiskManager rm;

   //--- Fixture 1: SL/TP distance math
   {
      double sl = rm.CalculateStopLossDistance(0.0010); // atr * 1.5
      Assert(AlmostEqual(sl, 0.0015), "CalculateStopLossDistance(0.0010) == 0.0015 (atr * 1.5)");

      double tp = rm.CalculateTakeProfitDistance(sl); // sl * 2.0
      Assert(AlmostEqual(tp, 0.0030), "CalculateTakeProfitDistance(0.0015) == 0.0030 (sl * 2.0)");
   }

   //--- Fixture 2: risk-based lot sizing (equity=10000, risk=1%, sl=0.0015, tickValue=1.0, tickSize=0.00001)
   //    riskAmount=100, slDistanceInTicks=150, riskPerLot=150, raw lot=0.6667 -> normalized to 0.66
   {
      double lot = rm.CalculateLotSize(0.0015, 1.0, 0.00001, 10000.0, STATE_FLAT, 0.01, 100.0, 0.01);
      Assert(AlmostEqual(lot, 0.66, 0.001), "Risk-based lot size normalizes to 0.66");
   }

   //--- Fixture 3: same as Fixture 2, but in RECOVERY - lot is roughly halved
   {
      double lot = rm.CalculateLotSize(0.0015, 1.0, 0.00001, 10000.0, STATE_RECOVERY, 0.01, 100.0, 0.01);
      Assert(AlmostEqual(lot, 0.33, 0.001), "RECOVERY state roughly halves the lot size (0.66 -> 0.33)");
   }

   //--- Fixture 4: NormalizeLot clamps below the broker minimum up to minLot
   {
      double lot = rm.NormalizeLot(0.001, 0.01, 100.0, 0.01);
      Assert(AlmostEqual(lot, 0.01), "NormalizeLot clamps a tiny lot up to the broker minimum");
   }

   //--- Fixture 5: NormalizeLot clamps above the broker maximum down to maxLot
   {
      double lot = rm.NormalizeLot(1000.0, 0.01, 100.0, 0.01);
      Assert(AlmostEqual(lot, 100.0), "NormalizeLot clamps an oversized lot down to the broker maximum");
   }

   //--- Fixture 6: Validate() rejects DIRECTION_NONE outright
   {
      double outLot, outSl, outTp;
      bool ok = rm.Validate(DIRECTION_NONE, STATE_FLAT, 0.0010, 1.0, 0.00001, 10000.0,
                             0.01, 100.0, 0.01, outLot, outSl, outTp);
      Assert(ok == false, "Validate() rejects DIRECTION_NONE");
      Assert(AlmostEqual(outLot, 0.0), "Validate() leaves outLot at 0.0 when rejecting");
   }

   //--- Fixture 7: Validate() rejects a zero/invalid ATR (e.g. right after EA start)
   {
      double outLot, outSl, outTp;
      bool ok = rm.Validate(DIRECTION_BUY, STATE_FLAT, 0.0, 1.0, 0.00001, 10000.0,
                             0.01, 100.0, 0.01, outLot, outSl, outTp);
      Assert(ok == false, "Validate() rejects a zero ATR (can't size risk safely)");
   }

   //--- Fixture 8: Validate() succeeds on a normal, healthy input set
   {
      double outLot, outSl, outTp;
      bool ok = rm.Validate(DIRECTION_BUY, STATE_FLAT, 0.0010, 1.0, 0.00001, 10000.0,
                             0.01, 100.0, 0.01, outLot, outSl, outTp);
      Assert(ok == true,                       "Validate() succeeds on a healthy input set");
      Assert(AlmostEqual(outSl, 0.0015),         "Validate() computes the same SL distance as CalculateStopLossDistance");
      Assert(AlmostEqual(outTp, 0.0030),         "Validate() computes the same TP distance as CalculateTakeProfitDistance");
      Assert(AlmostEqual(outLot, 0.66, 0.001),   "Validate() computes the same lot size as CalculateLotSize");
   }

   PrintTestSummary("Test_RiskManager");
}
//+------------------------------------------------------------------+
