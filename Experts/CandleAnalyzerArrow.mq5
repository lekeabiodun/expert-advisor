#include <Trade\Trade.mqh>
CTrade trade;
enum ENTRY_TYPE {
    BUY_ENTRY,                // BUY_ENTRY Signal
    SELL_ENTRY                // SELL_ENTRY Signal
};
enum TREND_TYPE {
    BULLISH,            // Bullish/Uptrend Market
    BEARISH             // Bearish/Downtrend Market
};
enum TRADE_BEHAVIOUR {   
   REGULAR_BEHAVIOUR,   // Take Regular trade
   BUY_BEHAVIOUR,       // Only Take BUY_ENTRY Trade
   SELL_BEHAVIOUR       // Only Take SELL_ENTRY Trade
};

input group                                        "============  EA Settings  ===============";
input int                                          EXPERT_MAGIC = 11235813;     // Magic Number
input TRADE_BEHAVIOUR                              tradeBehaviour = REGULAR_BEHAVIOUR;    // Trading Behaviour

input group                                       "============  Money Management Settings ===============";
input double                                       lotSize=0.1; // Lot Size
input double                                       stopLoss = 10; // Stop Loss in Pips
input double                                       takeProfit = 20; // Take Profit in Pips


static datetime timestamp;

int SlowMovingAverageHandle = iMA(_Symbol, _Period, 48, 0, MODE_SMA, PRICE_CLOSE);

int count = 0;

int OnInit()
{
    ChartIndicatorAdd(0,0,SlowMovingAverageHandle);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    
}

void OnTick()
{
   datetime time = iTime(Symbol(), Period(), 0);
   
   if(timestamp != time) {
   
        timestamp = time;
      
        MqlRates PriceInformation[];
        ArraySetAsSeries(PriceInformation, true);
        int data = CopyRates(Symbol(), Period(), 0, 3, PriceInformation);
        Print("Count: ", count, " = ", (count % 9));
        
        if(PriceInformation[1].close > PriceInformation[1].open)
        {
            count = 0;
        }
        
        if(count % 9 == 0 && count != 0)
        {
            takeTrade(BUY_ENTRY);
            ObjectCreate(Symbol(), (PriceInformation[1].high), OBJ_ARROW_UP, 0, PriceInformation[1].time, (PriceInformation[1].low-2));
            ObjectSetInteger(Symbol(), (PriceInformation[1].high), OBJPROP_COLOR, clrRed);
            ObjectSetInteger(Symbol(), (PriceInformation[1].high), OBJPROP_WIDTH, 1);
        }
        count++;
   }
   

}


void takeTrade(ENTRY_TYPE entryType) {
   double Bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
   
   if(entryType == BUY_ENTRY){
       trade.SetExpertMagicNumber(EXPERT_MAGIC);
       trade.Buy(lotSize, Symbol(), Bid, setStopLoss(Bid, BUY_ENTRY), setTakeProfit(Bid, BUY_ENTRY), "-----BUY_ENTRYing----");
   }
   if(entryType == SELL_ENTRY){
       trade.SetExpertMagicNumber(EXPERT_MAGIC);
       trade.Sell(lotSize, Symbol(), Bid, setStopLoss(Bid, SELL_ENTRY), setTakeProfit(Bid, SELL_ENTRY), "-----SELL_ENTRYing-----");
   }
}

double setStopLoss(double Bid, ENTRY_TYPE entryType){
   if(!stopLoss){ return 0.0; }
   return calculateStopLoss(Bid, entryType);
}

double calculateStopLoss(double Bid, ENTRY_TYPE entryType){
   if(entryType == BUY_ENTRY){ return Bid-stopLoss; }
   if(entryType == SELL_ENTRY){ return Bid+stopLoss; }
   return 0.0;
}

double setTakeProfit(double Bid, ENTRY_TYPE entryType){
   if(!takeProfit){ return 0.0; }
   return calculateTakeProfit(Bid, entryType);
}

double calculateTakeProfit(double Bid, ENTRY_TYPE entryType){
   if(entryType == BUY_ENTRY){ return  Bid+takeProfit; }
   if(entryType == SELL_ENTRY){ return Bid-takeProfit; } 
   return 0.0;
}



