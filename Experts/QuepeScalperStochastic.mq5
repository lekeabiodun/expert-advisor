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

enum MARKET_TREND{Bullish, Bearish, Sideway};

input group                                        "============  EA Settings  ===============";
input int                                          EXPERT_MAGIC = 11235813;     // Magic Number
input TRADE_BEHAVIOUR                              tradeBehaviour = REGULAR_BEHAVIOUR;    // Trading Behaviour

input group                                       "============  Stochastic Settings  ===============";
input bool                                         stochFactor = true; // Use Stochastic
input int                                          stochKperiod = 5; // % K Period
input int                                          stochDperiod = 3; // % D Period
input int                                          stochSlowing = 3; // Slowing
input ENUM_STO_PRICE                               stochPrice = STO_LOWHIGH;  // Stochastic Applied Price
input ENUM_MA_METHOD                               stochMode = MODE_SMA; // Stochastic Method
input int                                          overbought = 80; // Overbought Level
input int                                          oversold = 20; // Oversold level

input group                                       "============  Money Management Settings ===============";
input double                                       lotSize=1; // Lot Size
input double                                       stopLoss = 0.0; // Stop Loss in PiPs
input double                                       takeProfit = 0.0; // Take Profit in PiPs
input int                                          tradeTime = 50; // Time to trade

input group                                       "============  Candle Scalp Settings ===============";
input bool                                        uptrend = false; // Buy On Uptrend
input bool                                        downtrend = false; // Sell On Downtrend

static datetime timestamp;
string patternArray[100];
string search = "";

int tradeStartTime = (int)TimeCurrent();
int tradeCurrentTime = (int)TimeCurrent();

int OnInit()
{
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{

   
}

void OnTick()
{
   tradeCurrentTime   = (int)TimeCurrent();
   
   tradeTimer();

   datetime time = iTime(Symbol(), PERIOD_M1, 0);
      
   if(timestamp != time) {
   
        timestamp = time;
      
        if(marketTrend(Bullish) && uptrend)
        {
            if(PositionsTotal())
            {
                trade.PositionClose(PositionGetSymbol(0));
            }
            takeTrade(BUY_ENTRY);  
        
        }
        if(marketTrend(Bearish) && downtrend)
        {
            if(PositionsTotal())
            {
                trade.PositionClose(PositionGetSymbol(0));
            }
            takeTrade(SELL_ENTRY);  
        
        }
   }
}



void takeTrade(ENTRY_TYPE entryType) {
   double Bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
   
   tradeStartTime = (int)TimeCurrent();
   
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

bool marketTrend(MARKET_TREND trend){
    
   if(!stochFactor) return true;
   double KArray[], DArray[];
   ArraySetAsSeries(KArray, true);
   ArraySetAsSeries(DArray, true);      
   int Stochastic = iStochastic(_Symbol, _Period, stochKperiod, stochDperiod, stochSlowing, stochMode, stochPrice);
   CopyBuffer(Stochastic, 0, 0, 3, KArray);
   CopyBuffer(Stochastic, 1, 0, 3, DArray);
   if(trend == Bullish && KArray[0] < oversold && DArray[0] < oversold && KArray[0] > DArray[0] && KArray[1] < DArray[1]) { return true; }
   if(trend == Bearish && KArray[0] > overbought && DArray[0] > overbought && KArray[0] < DArray[0] && KArray[1] > DArray[1]) { return true; }
   return false;
}

void tradeTimer()
{
    if(PositionsTotal() && tradeTime)
    {
        if((tradeCurrentTime - tradeStartTime) >= tradeTime)
        {
        
            trade.PositionClose(PositionGetSymbol(0));
        }
    }
}