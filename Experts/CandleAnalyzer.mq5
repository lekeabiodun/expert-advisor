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
input double                                       stopLoss = 0.1; // Stop Loss in Pips
input double                                       takeProfit = 20; // Take Profit in Pips

// Date and Time
static datetime timestamp;
static datetime timestamp_24;
static datetime timestamp_1;

// Price
double opening_price_of_day = 0.0;
double closing_price_of_day = 0.0;
double open_price = 0.0;
double close_price = 0.0;

// Days
int market_days = 0;

// Spike
double spike = 0;
double daily_spike = 0;
double spike_count = 0;
double highest_spike = 0;
double lowest_spike = 0;
double total_spike = 0;

int sell_candle = 0;
int total_candle = 0;
int long_candle = 0;


double sell_count_D1 = 0;
double buy_count_D1 = 0;
double total_sell_D1 = 0;
double total_buy_D1 = 0;
double total_sell = 0;
double total_buy = 0;
double total_buy_sell_D1 = 0;

int OnInit()
{
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    Print("Total Analyze Days: ", market_days);
    Print("Total Spike: ", total_spike);
    Print("Total Sell: ", sell_candle);
    Print("Total Long Candle: ", long_candle);
    Print("Total Sell Pips D1: ", total_sell_D1);
    Print("Total Buy Pips D1: ", total_buy_D1);
    Print("Total Sell Pips: ", total_sell);
    Print("Total Buy Pips: ", total_buy);
    Print("Total Buy & Sell Pips D1: ", total_buy_sell_D1);
    Print("Open Price of the day: ", opening_price_of_day);
    Print("Close Price of the day: ", close_price);
    Print("Lowest SPike: ", lowest_spike);
    
    Print("Buy Count: ", buy_count_D1);
    Print("Sell Count: ", sell_count_D1);
    
    
    Print("Highest SPike: ", highest_spike);    
    Print("Total Candle: ", total_candle);
}

void OnTick()
{
   datetime time = iTime(Symbol(), Period(), 0);
   
   if(timestamp != time) {
   
        timestamp = time;
      
        MqlRates PriceInformation[];
        ArraySetAsSeries(PriceInformation, true);
        int data = CopyRates(Symbol(), Period(), 0, 3, PriceInformation);
        
        if(sell_candle == 0)
        {
            opening_price_of_day = PriceInformation[1].open;
        }
        
        if(PriceInformation[1].close > PriceInformation[1].open)
        {
            spike++;
            spike_count++;
            total_spike++;
            total_buy_D1 += PriceInformation[1].high - PriceInformation[1].low;
            total_buy_sell_D1 += PriceInformation[1].high - PriceInformation[1].low;
        }  
        if(PriceInformation[1].close < PriceInformation[1].open)
        {
            sell_candle++;
            total_sell_D1 += PriceInformation[1].open - PriceInformation[1].low;
            total_buy_sell_D1 += PriceInformation[1].open - PriceInformation[1].low;
        }
        if((PriceInformation[1].high - PriceInformation[1].low) >= 19)
        {
            long_candle++;
        }
        total_candle++;
        open_price = PriceInformation[1].open;
        close_price = PriceInformation[1].close;
   }
   
//   datetime time_1 = iTime(Symbol(), PERIOD_D1, 0);
//   
//   if(timestamp_1 != time_1){ 
//        timestamp_1 = time_1;
//        highest_spike = MathMax(spike, highest_spike);
//        if(spike > 100) lowest_spike = MathMin(spike, 125);
//        market_days++;
//        spike = 0;
//   }
   
   datetime time_24 = iTime(Symbol(), PERIOD_D1, 0);
   
   if(timestamp_24 != time_24){ 
        timestamp_24 = time_24;
        
        if(total_sell_D1 > total_buy_D1) sell_count_D1++;
        if(total_sell_D1 < total_buy_D1) buy_count_D1++;
        total_buy_D1 = 0;
        total_sell_D1 = 0;
        
        //highest_spike = MathMax(total_buy, highest_spike);
        //lowest_spike = MathMin(spike, 1000);
        //market_days++;
        //spike = 0;
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


