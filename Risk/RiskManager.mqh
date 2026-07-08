//+------------------------------------------------------------------+
//| RiskManager.mqh                                                    |
//| Position sizing + SL/TP distance math, and a single Validate()     |
//| entry point that EA.mq5 calls at step 9 of the pipeline.           |
//|                                                                    |
//| Same pattern as the rest of Risk/: every terminal-derived value     |
//| (tick value/size, equity, broker lot limits) is passed in by the   |
//| caller rather than read internally, so every method here is        |
//| testable with plain numbers (see Tests/Test_RiskManager.mq5).      |
//|                                                                    |
//| When SystemState == RECOVERY, lot size is multiplied by             |
//| InpRecoveryLotMultiplier - this is what actually reduces risk       |
//| while RECOVERY is active (RECOVERY itself never blocks a trade,    |
//| see the design note in Strategy/StateMachine.mqh).                 |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Types.mqh"
#include "../Core/Config.mqh"

class CRiskManager
{
public:
   /// SL distance in price terms.
   double CalculateStopLossDistance(double atr)
   {
      return atr * InpStopLossATRMultiplier;
   }

   /// TP distance in price terms, derived from the SL distance.
   double CalculateTakeProfitDistance(double slDistancePrice)
   {
      return slDistancePrice * InpTakeProfitRR;
   }

   /// Risk-based (or fixed) lot size, clamped/rounded to the broker's
   /// min/max/step and reduced if the system is in RECOVERY mode.
   double CalculateLotSize(double slDistancePrice, double tickValue, double tickSize,
                            double equity, SystemState state,
                            double minLot, double maxLot, double lotStep)
   {
      double lot;

      if(InpFixedLot > 0.0)
      {
         lot = InpFixedLot;
      }
      else
      {
         double riskAmount        = equity * (InpRiskPercent / 100.0);
         double slDistanceInTicks = (tickSize > 0.0) ? (slDistancePrice / tickSize) : 0.0;
         double riskPerLot        = slDistanceInTicks * tickValue;
         lot                      = (riskPerLot > 0.0) ? (riskAmount / riskPerLot) : 0.0;
      }

      if(state == STATE_RECOVERY)
         lot *= InpRecoveryLotMultiplier;

      return NormalizeLot(lot, minLot, maxLot, lotStep);
   }

   /// Rounds down to the broker's lot step and clamps to [minLot, maxLot].
   double NormalizeLot(double lot, double minLot, double maxLot, double lotStep)
   {
      if(lotStep > 0.0)
         lot = MathFloor(lot / lotStep + 0.0000001) * lotStep; // epsilon guards float rounding

      lot = MathMax(minLot, MathMin(maxLot, lot));

      double factor = 100.0; // 2 decimal places is enough for every broker's lot step
      return MathRound(lot * factor) / factor;
   }

   /// Single entry point for EA.mq5's step 9. Computes SL/TP distance and
   /// lot size, and vetoes the trade (returns false) if anything looks
   /// unsafe to act on - e.g. ATR not ready yet right after EA start.
   bool Validate(TradeDirection direction, SystemState state, double atr,
                 double tickValue, double tickSize, double equity,
                 double minLot, double maxLot, double lotStep,
                 double &outLot, double &outSlDistance, double &outTpDistance)
   {
      outLot        = 0.0;
      outSlDistance = 0.0;
      outTpDistance = 0.0;

      if(direction == DIRECTION_NONE)
         return false;

      outSlDistance = CalculateStopLossDistance(atr);
      if(outSlDistance <= 0.0)
         return false; // ATR not ready yet (e.g. right after EA start) - can't size risk safely

      outTpDistance = CalculateTakeProfitDistance(outSlDistance);
      outLot        = CalculateLotSize(outSlDistance, tickValue, tickSize, equity, state,
                                        minLot, maxLot, lotStep);

      if(outLot <= 0.0)
         return false; // defensive - should not happen once NormalizeLot clamps to minLot > 0

      return true;
   }
};
//+------------------------------------------------------------------+
