//+------------------------------------------------------------------+
//| TradeManager.mqh                                                   |
//| Implements ITradeExecutor using MT5's standard CTrade class.       |
//| This is the only module in the project that actually sends orders  |
//| to the broker - everything upstream (Pattern/Classification/       |
//| Strategy/Risk) only computes numbers and decisions.                |
//|                                                                    |
//| NOT unit-testable the way the rest of Risk/ is: opening/closing    |
//| real positions needs a live/demo terminal connection. Verify this  |
//| module by attaching the EA to a DEMO account chart and watching    |
//| the Experts/Trade tabs - see the Batch 5 section of README.txt.    |
//+------------------------------------------------------------------+
#property strict

#include <Trade/Trade.mqh>
#include "../Core/Interfaces.mqh"
#include "../Core/Config.mqh"

class CTradeManager : public ITradeExecutor
{
private:
   CTrade m_trade;

public:
   CTradeManager()
   {
      m_trade.SetExpertMagicNumber(GetMagicNumber());
      m_trade.SetDeviationInPoints(10);
      m_trade.SetTypeFillingBySymbol(_Symbol);
   }

   virtual bool OpenBuy(double lot, double sl, double tp, string comment)
   {
      double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      return m_trade.Buy(lot, _Symbol, price, sl, tp, comment);
   }

   virtual bool OpenSell(double lot, double sl, double tp, string comment)
   {
      double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      return m_trade.Sell(lot, _Symbol, price, sl, tp, comment);
   }

   virtual bool ModifyPosition(ulong ticket, double sl, double tp)
   {
      return m_trade.PositionModify(ticket, sl, tp);
   }

   /// Closes every open position for this EA's magic number on this
   /// symbol (used by the Emergency Stop kill switch).
   virtual bool CloseAll()
   {
      bool allClosed = true;

      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0)
            continue;
         if(!PositionSelectByTicket(ticket))
            continue;
         if(PositionGetString(POSITION_SYMBOL) != _Symbol)
            continue;
         if((long)PositionGetInteger(POSITION_MAGIC) != GetMagicNumber())
            continue;

         if(!m_trade.PositionClose(ticket))
            allClosed = false;
      }

      return allClosed;
   }
};
//+------------------------------------------------------------------+
