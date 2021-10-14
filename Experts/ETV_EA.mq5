#include <Trade\Trade.mqh>
CTrade trade;
enum ENTRY_TYPE {
    BUY,                // BUY 
    SELL               // SELL
};
enum MARKET_SIGNAL {
    BULLISH,                // BUY 
    BEARISH               // SELL
};
enum TRADE_BEHAVIOUR {   
   REGULAR_BEHAVIOUR,       // Regular
   OPPOSITE_BEHAVIOUR       // Opposite
};

enum MARKET_TREND{Bullish, Bearish, Sideway};

input group                                        "============  EA Settings  ===============";
input int                                          EXPERT_MAGIC = 1805;     // Magic Number
input TRADE_BEHAVIOUR                              tradeBehaviour = REGULAR_BEHAVIOUR;    // Trading Behaviour

input group                                       "============  Money Management Settings ===============";
input double                                       lotSize=1; // Lot Size
input double                                       stopLoss = 0.0; // Stop Loss in PiPs
input double                                       takeProfit = 0.0; // Take Profit in PiPs
input int                                          tradeTime = 50; // Time to trade

input group                                       "============  Candle Scalp Settings ===============";
input bool                                        buyUptrend = false; // Buy On Uptrend
input bool                                        sellDowntrend = false; // Sell On Downtrend
input bool                                        tradeOppositeOrder = false; // Trade Opposite Pending Order

static datetime timestamp;
string patternArray[100];
string search = "";

int tradeStartTime = (int)TimeCurrent();
int tradeCurrentTime = (int)TimeCurrent();

int ETVHandle = iCustom(NULL, 0, "ETV");


void OnTick(){

   tradeCurrentTime   = (int)TimeCurrent();
   
   tradeTimer();

   datetime time = iTime(Symbol(), PERIOD_M1, 0);
      
   if(timestamp != time) {
   
        timestamp = time;
      
        if(marketSignal(BULLISH) && buyUptrend)
        {
            if(PositionsTotal())
            {
                trade.PositionClose(PositionGetSymbol(0));
            }
            takeTrade(BUY);  
        
        }
        if(marketSignal(BEARISH)&& sellDowntrend)
        {
            if(PositionsTotal())
            {
                trade.PositionClose(PositionGetSymbol(0));
            }
            takeTrade(SELL);  
        
        }
   }
    

}

bool marketSignal(MARKET_SIGNAL signal)
{
   double ETVSell[], ETVBuy[];
   ArraySetAsSeries(ETVSell, true);
   ArraySetAsSeries(ETVBuy, true);
   CopyBuffer(ETVHandle, 4, 0, 3, ETVSell);
   CopyBuffer(ETVHandle, 3, 0, 3, ETVBuy);
   if(signal == BULLISH && ETVBuy[0] != EMPTY_VALUE) { return true; }
   if(signal == BEARISH && ETVSell[0] != EMPTY_VALUE) { return true; }
   return false;
}

void takeTrade(ENTRY_TYPE entryType) {
   double Bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
   
   tradeStartTime = (int)TimeCurrent();
   double openPrice = iOpen(NULL,Period(),0);
   
   if(tradeBehaviour == OPPOSITE_BEHAVIOUR){
        if(entryType == BUY){ entryType = SELL; }
        if(entryType == SELL){ entryType = BUY; }   
   }
   
   if(entryType == BUY){
       trade.SetExpertMagicNumber(EXPERT_MAGIC);
       trade.Buy(lotSize, Symbol(), Bid, setStopLoss(Bid, BUY), setTakeProfit(Bid, BUY));
       if(tradeOppositeOrder){
            trade.SellStop(lotSize, Bid-(1000*Point()), Symbol(), 0, 0, ORDER_TIME_GTC,0);
       }
   }
   if(entryType == SELL){
       trade.SetExpertMagicNumber(EXPERT_MAGIC);
       trade.Sell(lotSize, Symbol(), Bid, setStopLoss(Bid, SELL), setTakeProfit(Bid, SELL));
       if(tradeOppositeOrder){
            trade.BuyStop(lotSize, Bid+(1000*Point()), Symbol(), 0, 0, ORDER_TIME_GTC,0);
       }
   }
}

double setStopLoss(double Bid, ENTRY_TYPE entryType){
   if(!stopLoss){ return 0.0; }
   return calculateStopLoss(Bid, entryType);
}

double calculateStopLoss(double Bid, ENTRY_TYPE entryType){
   if(entryType == BUY){ return Bid-stopLoss; }
   if(entryType == SELL){ return Bid+stopLoss; }
   return 0.0;
}

double setTakeProfit(double Bid, ENTRY_TYPE entryType){
   if(!takeProfit){ return 0.0; }
   return calculateTakeProfit(Bid, entryType);
}

double calculateTakeProfit(double Bid, ENTRY_TYPE entryType){
   if(entryType == BUY){ return  Bid+takeProfit; }
   if(entryType == SELL){ return Bid-takeProfit; } 
   return 0.0;
}




void tradeTimer()
{
    if(PositionsTotal() && tradeTime)
    {
        if((tradeCurrentTime - tradeStartTime) >= tradeTime)
        {
            for(int i=0; i < PositionsTotal(); i++)
            {
                trade.PositionClose(PositionGetSymbol(i));
            }
        }
    }
    if(OrdersTotal() && tradeTime)
    {
        if((tradeCurrentTime - tradeStartTime) >= tradeTime)
        {
        
            trade.OrderDelete(OrderGetTicket(0));
        }
    }
}