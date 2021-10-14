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

input group                                       "============  MACD Settings  ===============";
input bool                                         trendFactor = true; // Use Trend MACD
input ENUM_TIMEFRAMES                              trendTimeframe = PERIOD_CURRENT; // Trend Timeframe
input int                                          fastEMA = 12; // Trend Fast EMA
input int                                          slowEMA = 26; // Trend Slow EMA
input int                                          MACDSMA = 9; // Trend MACD SMA
input ENUM_APPLIED_PRICE                           MACDAppliedPrice = PRICE_CLOSE; // MACD Applied Price

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
   if(!trendFactor) return true;
   int MACDHandle = iMACD(Symbol(), trendTimeframe, fastEMA, slowEMA, MACDSMA, MACDAppliedPrice);
   double PriceArray[];
   CopyBuffer(MACDHandle, 0, 1, 3, PriceArray);
   float MacDValue = (PriceArray[0]);
   if(trend == Bullish && MacDValue > 0) { return true; }
   else if(trend == Bearish && MacDValue < 0) { return true; }
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