//+------------------------------------------------------------------+
//| DecisionEngine.mqh                                                 |
//| Implements IDecisionEngine. Converts the aggregated bull/bear/     |
//| neutral scores from PatternClassifier into a TradeDirection.       |
//|                                                                    |
//| A direction only "wins" if it clears an absolute minimum score AND |
//| beats the opposite direction by a dominance ratio - this rejects   |
//| both weak signals (low absolute score) and ambiguous ones (close   |
//| to a tie), rather than just picking whichever side is technically  |
//| higher.                                                             |
//|                                                                    |
//| NOTE (Phase 1 scope): neutralScore is accepted (the interface      |
//| requires it) but not yet used to suppress decisions during         |
//| high-indecision periods (lots of Doji/Spinning Top). Adding that   |
//| now would be a threshold with no backtest evidence behind it -     |
//| revisit once Batch 5+ backtesting shows it's actually needed.      |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Interfaces.mqh"
#include "../Core/Config.mqh"

class CDecisionEngine : public IDecisionEngine
{
public:
   virtual TradeDirection Decide(double bullishScore, double bearishScore, double neutralScore)
   {
      bool bullQualifies = (bullishScore >= InpMinScoreThreshold) &&
                           (bullishScore > bearishScore * InpDominanceRatio);

      bool bearQualifies = (bearishScore >= InpMinScoreThreshold) &&
                           (bearishScore > bullishScore * InpDominanceRatio);

      if(bullQualifies && !bearQualifies)
         return DIRECTION_BUY;

      if(bearQualifies && !bullQualifies)
         return DIRECTION_SELL;

      return DIRECTION_NONE; // no signal, too weak, or too close to call
   }
};
//+------------------------------------------------------------------+
