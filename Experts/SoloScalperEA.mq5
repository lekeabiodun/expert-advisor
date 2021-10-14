#include <Trade\Trade.mqh>
CTrade trade;
enum ENTRY_TYPE {
    BUY_ENTRY,                // BUY_ENTRY Signal
    SELL_ENTRY                // SELL_ENTRY Signal
};

enum TRADE_BEHAVIOUR {   
   BUY_BEHAVIOUR,       // Only BUY
   SELL_BEHAVIOUR       // Only SELL
};

input group                                        "============  EA Settings  ===============";
input int                                          EXPERT_MAGIC = 11235813;     // Magic Number
input TRADE_BEHAVIOUR                              tradeBehaviour = BUY_BEHAVIOUR;    // Trading Behaviour

input group                                       "============  Money Management Settings ===============";
input double                                       lotSize=0.1; // Lot Size
input double                                       stopLoss = 10; // Stop Loss in Pips
input double                                       takeProfit = 20; // Take Profit in Pips


static datetime timestamp;


int OnInit()
{
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
      
      if(tradeBehaviour == BUY_BEHAVIOUR)
      {
        takeTrade(BUY_ENTRY);
      }
      if(tradeBehaviour == SELL_BEHAVIOUR)
      {
        takeTrade(SELL_ENTRY);
      }
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



