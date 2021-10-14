#include <Trade\Trade.mqh>
CTrade trade;

enum marketSignal{
    BUY,                // BUY 
    SELL               // SELL
};
enum marketEntry {
   LONG,           // Only Long
   SHORT          // Only Short
};

enum tradeBehaviour {   
   REGULAR,       // Regular
   OPPOSITE       // Opposite
};

enum marketTrend{
    BULLISH, 
    BEARISH, 
};

static datetime timestamp;

input group                                        "============  EA Settings  ===============";
input int                                          EXPERT_MAGIC = 2390784; // Magic Number
input tradeBehaviour                               expertBehaviour = REGULAR; // Trading Behaviour

input group                                       "============  Position Management Settings ===============";
input bool                                         closeTradeOnNewSignal = true; // Close Trade on New Signal

input group                                       "============  Money Management Settings ===============";
input double                                       lotSize = 0.1; // Lot Size
input double                                       stopLoss = 0.0; // Stop Loss in Pips
input double                                       takeProfit = 0.0; // Take Profit in Pips
input int                                          tradeTime = 50; // Time to trade (secs)

input group                                       "============ PTL Settings ===============";
input int                                         inpFastLength = 3; // Fast length
input int                                         inpSlowLength = 7; // Slow length

input group                                       "============  Candle Scalp Settings ===============";
input bool                                        uptrend = false; // Buy On Uptrend
input bool                                        downtrend = false; // Sell On Downtrend

int tradeStartTime = (int)TimeCurrent();
int tradeCurrentTime = (int)TimeCurrent();
bool expertSignalBuy = false;
bool expertSignalSell = false;
int PTLHandle = iCustom(NULL, 0, "SPTL2", inpFastLength, inpSlowLength);

void OnTick(){
    
   tradeCurrentTime   = (int)TimeCurrent();
   
   market_signal();
   
   trade_timer();


   datetime time = iTime(_Symbol, _Period, 0);
   
   if(timestamp != time) {
      timestamp = time;

      if(expertSignalBuy && uptrend)
      {
         if(PositionsTotal()){ close_all_positions(); }
         if(OrdersTotal()) { close_all_orders(); }
         go(LONG); 
      }
      if(expertSignalSell && downtrend)
      {
         if(PositionsTotal()){ close_all_positions(); }
         if(OrdersTotal()) { close_all_orders(); }
         go(SHORT);
      }  
   }

}

void market_signal()
{
   double up[], down[], PTLArray[];
   ArraySetAsSeries(up, true);
   ArraySetAsSeries(down, true);
   ArraySetAsSeries(PTLArray, true);
   CopyBuffer(PTLHandle,5,1,3,up); 
   CopyBuffer(PTLHandle,6,1,3,down);
   CopyBuffer(PTLHandle,7,1,3,PTLArray);
   bool _BUY  = (MathMax(up[0],down[0]) < iOpen(NULL,Period(),1) && MathMax(up[1],down[1]) >= iOpen(NULL,Period(),2));  
   bool _SELL = (MathMin(up[0],down[0]) > iOpen(NULL,Period(),1) && MathMin(up[1],down[1]) <= iOpen(NULL,Period(),2));
   if(PTLArray[0] != EMPTY_VALUE && _BUY) 
   { 
        expertSignalBuy = true; 
        expertSignalSell = false;
   }
   if(PTLArray[0] != EMPTY_VALUE && _SELL) 
   { 
        expertSignalSell = true;
        expertSignalBuy = false; 
   }
}


void go(marketEntry entry) {
   double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
   
   tradeStartTime = (int)TimeCurrent();
   
   if(expertBehaviour == OPPOSITE){
        if(entry == LONG){ entry = SHORT; }
        if(entry == SHORT){ entry = LONG; }   
   }
   
   if(entry == LONG){
       trade.SetExpertMagicNumber(EXPERT_MAGIC);
       trade.Buy(lotSize, Symbol(), bid, setStopLoss(bid, LONG), setTakeProfit(bid, LONG));
   }
   if(entry == SHORT){
       trade.SetExpertMagicNumber(EXPERT_MAGIC);
       trade.Sell(lotSize, Symbol(), bid, setStopLoss(bid, SHORT), setTakeProfit(bid, SHORT));
   }
}

double setStopLoss(double bid, marketEntry entry){
   if(!stopLoss){ return 0.0; }
   return calculateStopLoss(bid, entry);
}

double calculateStopLoss(double bid, marketEntry entry){
   if(entry == LONG){ return bid-stopLoss; }
   if(entry == SHORT){ return bid+stopLoss; }
   return 0.0;
}

double setTakeProfit(double bid, marketEntry entry){
   if(!takeProfit){ return 0.0; }
   return calculateTakeProfit(bid, entry);
}

double calculateTakeProfit(double bid, marketEntry entry){
   if(entry == LONG){ return  bid+takeProfit; }
   if(entry == SHORT){ return bid-takeProfit; } 
   return 0.0;
}



void trade_timer()
{
    if(PositionsTotal() && tradeTime)
    {
        if((tradeCurrentTime - tradeStartTime) >= tradeTime)
        {
        
            close_all_positions();
        }
    }
    
    if(OrdersTotal() && tradeTime)
    {
        if((tradeCurrentTime - tradeStartTime) >= tradeTime)
        {
        
            close_all_orders();
        }
    }
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


void close_all_orders()
{
    if(OrdersTotal())
    {
        for(int i=0; i < OrdersTotal(); i++)
        {
             trade.OrderDelete(OrderGetTicket(i));
        }
    }
}

