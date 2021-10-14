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

input group                                         "============  Money Management Settings ===============";
input double                                        lotSize = 0.1; // Lot Size
input double                                        stopLoss = 0.0; // Stop Loss in Pips
input double                                        takeProfit = 0.0; // Take Profit in Pips
input group                                         "============  Scalp Settings ===============";
input bool                                          expertIsTakingBuyTrade = false; // Take Buy Trade
input bool                                          expertIsTakingSellTrade = false; // Take Sell Trade

int tradeStartTime = (int)TimeCurrent();
int tradeCurrentTime = (int)TimeCurrent();
static datetime timestamp;

int OnInit()
{
    Print("1 Samuel 30:8 King James Version");
    Print("And David inquired at the LORD, saying, Shall I pursue after this troop? shall I overtake them?");
    Print("And he answered him, Pursue: for thou shalt surely overtake them, and without fail recover all.");
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    Print("1 Samuel 30:8 King James Version");
    Print("And David inquired at the LORD, saying, Shall I pursue after this troop? shall I overtake them?");
    Print("And he answered him, Pursue: for thou shalt surely overtake them, and without fail recover all.");
}

void OnTick() 
{
    tradeCurrentTime = (int)TimeCurrent();

    // if(tradeCurrentTime - tradeStartTime >= expertTimer) { 
    //   tradeStartTime = tradeCurrentTime;
   datetime time = iTime(Symbol(), Period(), 0);

   if(timestamp != time) {
        timestamp = time;
        if(q_signal(BUY))
        { 
            takeTrade(LONG);
        }
        if(q_signal(SELL))
        {
            takeTrade(SHORT);
        }  
    }
}

void takeTrade(marketEntry entry) {
   if(entry == LONG && expertIsTakingBuyTrade) {
        double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
        trade.Buy(lotSize, Symbol(), ask, setStopLoss(ask, LONG), setTakeProfit(ask, LONG));
   }
   if(entry == SHORT && expertIsTakingSellTrade) {
        double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
        trade.Sell(lotSize, Symbol(), bid, setStopLoss(bid, SHORT), setTakeProfit(bid, SHORT));
   }
}

double setStopLoss(double price, marketEntry entry)
{
   if(!stopLoss){ return 0.0; }
   if(entry == LONG){ return price-stopLoss; }
   if(entry == SHORT){ return price+stopLoss; }
   return 0.0;
}

double setTakeProfit(double price, marketEntry entry)
{
   if(!takeProfit){ return 0.0; }
   if(entry == LONG){ return  price+takeProfit; }
   if(entry == SHORT){ return price-takeProfit; } 
   return 0.0;
}

bool q_signal(marketSignal signal)
{
   if(signal == BUY && iHigh(Symbol(), Period(), 1) > iOpen(Symbol(), Period(), 1))
    {
        return true;
    }
    if(signal == SELL && iLow(Symbol(), Period(), 1) < iOpen(Symbol(), Period(), 1))
    {
        return true;
    }
    return false;
}


