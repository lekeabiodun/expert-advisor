#include <Trade\Trade.mqh>
CTrade trade;

enum marketSignal{
    BUY,                // BUY 
    SELL                // SELL
};
enum marketEntry {
   LONG,                // Only Long
   SHORT                // Only Short
};
enum tradeBehaviour {   
   REGULAR,             // Regular
   OPPOSITE             // Opposite
};

enum marketTrend{
    BULLISH, 
    BEARISH, 
    SIDEWAYS
};
input group                                         "============  EA Settings  ===============";
input int                                           EXPERT_MAGIC = 555784; // Magic Number
input tradeBehaviour                                expertBehaviour = REGULAR; // Trading Behaviour
input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 0.1; // Lot Size
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input group                                         "============  Position Management Settings ===============";
input bool                                          closeOnOppositeSignal = true; // Close Trade on Opposite Signal
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

static datetime timestamp;

void OnTick() 
{
   datetime time = iTime(_Symbol, PERIOD_M1, 0);

   if(timestamp != time) 
   {
        timestamp = time;
        if(wpr_signal(BUY))
        { 
            close_opposite_trade(LONG); 
            enterFor(LONG);
            wprSignalBuy = false;
            wprSignalSell = false;
        }
        if(wpr_signal(SELL))
        {
            close_opposite_trade(SHORT);  
            enterFor(SHORT);
            wprSignalBuy = false;
            wprSignalSell = false;
        }
   }


}


void takeTrade(marketEntry entry) 
{
   double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
      
   if(expertBehaviour == OPPOSITE)
   {
        if(entry == LONG){ entry = SHORT; }
        if(entry == SHORT){ entry = LONG; }   
   }
   
   if(entry == LONG)
   {
       trade.SetExpertMagicNumber(EXPERT_MAGIC);
       trade.Buy(lotSize, Symbol(), bid, setStopLoss(bid, LONG), setTakeProfit(bid, LONG));
   }
   if(entry == SHORT)
   {
       trade.SetExpertMagicNumber(EXPERT_MAGIC);
       trade.Sell(lotSize, Symbol(), bid, setStopLoss(bid, SHORT), setTakeProfit(bid, SHORT));
   }
}

double setStopLoss(double bid, marketEntry entry)
{
   if(!stopLoss){ return 0.0; }
   return calculateStopLoss(bid, entry);
}

double calculateStopLoss(double bid, marketEntry entry)
{
   if(entry == LONG){ return bid-stopLoss; }
   if(entry == SHORT){ return bid+stopLoss; }
   return 0.0;
}

double setTakeProfit(double bid, marketEntry entry)
{
   if(!takeProfit){ return 0.0; }
   return calculateTakeProfit(bid, entry);
}

double calculateTakeProfit(double bid, marketEntry entry)
{
   if(entry == LONG){ return  bid+takeProfit; }
   if(entry == SHORT){ return bid-takeProfit; } 
   return 0.0;
}

void close_all_positions()
{
    if(PositionsTotal())
    {
        for(int i=0; i < PositionsTotal(); i++)
        {
            trade.PositionClose(PositionGetSymbol(i));
        }
    }
}

void close_opposite_trade(marketEntry entry)
{

    if(PositionsTotal() && entry == LONG && closeOnOppositeSignal)
    {
        for(int i=0; i < PositionsTotal()+10; i++)
        {
            PositionSelect(Symbol());
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            {
                trade.PositionClose(Symbol());
            }
        }
    }
    if(PositionsTotal() && entry == SHORT && closeOnOppositeSignal)
    {
        for(int i=0; i < PositionsTotal()+10; i++)
        {
            PositionSelect(Symbol());
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {
                trade.PositionClose(Symbol());
            }
        }
    }
}

void enterFor(marketEntry entry)
{
    if(entry == LONG && expertIsTakingBuyTrade)
    {
        takeTrade(LONG);
    }
    if(entry == SHORT && expertIsTakingSellTrade)
    {
        takeTrade(SHORT);
    }
}


input group                                       "============  Williams Percentage Settings  ===============";
input bool                                         wprFactor = true; // Use WPR 
input int                                          wprPeriod = 100; // WPR Period
input int                                          wprOverBoughtLevel = -20; // WPR Overbought Level
input int                                          wprOverSoldLevel = -80; // WPR OverSold Level

bool wprSignalBuy = false;
bool wprSignalSell = false;


bool wpr_signal(marketSignal signal){
   if(!wprFactor) return true;
   int wprHandle = iWPR(_Symbol, Period(), wprPeriod);
   double wprArray[];
   ArraySetAsSeries(wprArray, true);
   CopyBuffer(wprHandle, 0, 0, 2, wprArray);
   if(signal == BUY && wprArray[0] >= wprOverSoldLevel && wprArray[0] < wprOverBoughtLevel && wprSignalBuy) 
    { 
        return true; 
    }
    if(signal == SELL && wprArray[0] <= wprOverBoughtLevel && wprArray[0] > wprOverSoldLevel && wprSignalSell) 
    { 
        return true; 
    }

    if(wprArray[0] < wprOverSoldLevel)
    {
        wprSignalBuy = true;
        wprSignalSell = false;
    }
    if(wprArray[0] > wprOverBoughtLevel)
    {
        wprSignalSell = true;
        wprSignalBuy = false;
    }
   return false;
}