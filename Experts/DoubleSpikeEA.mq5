#include <Trade\Trade.mqh>
CTrade trade;
enum ENTRY_TYPE {
    BUY_ENTRY,                // BUY
    SELL_ENTRY               // SELL
};

enum TRADE_BEHAVIOUR {   
   REGULAR_BEHAVIOUR,       // Regular
   OPPOSITE_BEHAVIOUR       // Opposite
};

input group                                        "============  EA Settings  ===============";
input int                                          EXPERT_MAGIC = 1123813;     // Magic Number
input TRADE_BEHAVIOUR                              tradeBehaviour = REGULAR_BEHAVIOUR;    // Trading Behaviour

input group                                       "============  Money Management Settings ===============";
input double                                       lotSize=1; // Lot Size
input double                                       stopLoss = 0.0; // Stop Loss in Pips
input double                                       takeProfit = 0.0; // Take Profit in Pips

static datetime timestamp;
bool spike = false;
bool doubleSpike = false;

int spikeCounter = 0;
int sellCounter = 0;

int OnInit()
{

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{

   
}


void OnTick()
{
   datetime time = iTime(Symbol(), PERIOD_M1, 0);
      
   if(timestamp != time) {
   
        timestamp = time;
      
        MqlRates PriceInformation[];
        ArraySetAsSeries(PriceInformation, true);
        int data = CopyRates(Symbol(), Period(), 0, 3, PriceInformation);
        
        if(PriceInformation[1].close > PriceInformation[1].open)
        {
            spike = true;
            spikeCounter++;
        } 
         
        if(PriceInformation[1].close < PriceInformation[1].open)
        {
            spike = false;
            spikeCounter = 0;
        }
        
        if(spike && spikeCounter >= 2) { doubleSpike = true; spike = false; }
        
        if(doubleSpike && spike)
        {
            if(PositionsTotal())
            {
                trade.PositionClose(PositionGetSymbol(0));
            }
            
            takeTrade(SELL_ENTRY);
            
            spike = false; 
            doubleSpike = false; 
            spikeCounter = 0; 
        
        }
        
   }
}



void takeTrade(ENTRY_TYPE entryType) {
   double Bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
   
   if(tradeBehaviour == OPPOSITE_BEHAVIOUR){
        if(entryType == BUY_ENTRY){ entryType = SELL_ENTRY; }
        if(entryType == SELL_ENTRY){ entryType = BUY_ENTRY; }   
   }
   
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