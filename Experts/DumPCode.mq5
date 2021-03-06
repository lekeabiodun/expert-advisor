//+------------------------------------------------------------------+
//|                                                     DumPCode.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+



static datetime timestamp;
int status = 1;
double tradingRange = 0;
double highestRange = 0;
double lowestRange = 0;

int count = 1;

int SlowMovingAverageHandle = iMA(_Symbol, _Period, 50, 0, MODE_LWMA, PRICE_CLOSE);
int FastMovingAverageHandle = iMA(_Symbol, _Period, 14, 0, MODE_LWMA, PRICE_CLOSE);

int OnInit() {
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {

}

void OnTick()  {

   datetime time = iTime(_Symbol, _Period, 0);
   
   if(timestamp != time) {
        
      timestamp = time;
   
      int HighestCandle = iHighest(Symbol(), Period(), MODE_HIGH,100,1);
      int LowestCandle = iLowest(Symbol(), Period(), MODE_LOW, 100, 1);
      
//      double High[], Low[];
//      ArraySetAsSeries(Low, true);
//      ArraySetAsSeries(High, true);
//      
//      CopyHigh(Symbol(), Period(), 0, 100, High);
//      CopyLow(Symbol(), Period(), 0, 100, Low);
//      
//      HighestCandle = ArrayMaximum(High, 0, 100);
//      LowestCandle = ArrayMinimum(Low, 0, 100);      
//      Print("High[0]: ", High[0]);
//      Print("High[1]: ", High[1]);
//      Print("High[2]: ", High[2]);
//      Print("High[3]: ", High[3]);
//      
//      
//      Print("Low[0]: ", Low[0]);
//      Print("Low[1]: ", Low[1]);
//      Print("Low[2]: ", Low[2]);
//      Print("Low[3]: ", Low[3]);

      MqlRates PriceInformation[];
      
      ArraySetAsSeries(PriceInformation, true);
      
      int Data = CopyRates(Symbol(), Period(), 0, Bars(Symbol(), Period()), PriceInformation);
   
//   
//    
//   ObjectCreate(Symbol(), IntegerToString(time), OBJ_ARROW_UP, 0, TimeCurrent(), (PriceInformation[LowestCandle].low));
//   ObjectSetInteger(Symbol(), IntegerToString(time), OBJPROP_COLOR, clrGreen);
//   ObjectSetInteger(Symbol(), IntegerToString(time), OBJPROP_FILL, clrGreen);
//   ObjectSetInteger(Symbol(), IntegerToString(time), OBJPROP_WIDTH, 3);
   
   
      ObjectCreate(Symbol(), "Arrow3", OBJ_ARROW_UP, 0, TimeCurrent(), (PriceInformation[LowestCandle].low));
      ObjectSetInteger(Symbol(), "Arrow3", OBJPROP_COLOR, clrGreen);
      ObjectSetInteger(Symbol(), "Arrow3", OBJPROP_WIDTH, 3);
      //ObjectMove(Symbol(), "Arrow3", 0, 0, PriceInformation[LowestCandle].low);
   
   
   
      ObjectCreate(0, "Line1", OBJ_HLINE, 0, 0, PriceInformation[HighestCandle].high);
      ObjectSetInteger(0, "Line1", OBJPROP_COLOR, clrAqua);
      ObjectSetInteger(0, "Line1", OBJPROP_WIDTH, 3);
      ObjectMove(0, "Line1", 0, 0, PriceInformation[HighestCandle].high);
      
      
      ObjectCreate(0, "Line2", OBJ_HLINE, 0, 0, PriceInformation[LowestCandle].low);
      ObjectSetInteger(0, "Line2", OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, "Line2", OBJPROP_WIDTH, 3);
      ObjectMove(0, "Line2", 0, 0, PriceInformation[LowestCandle].low);

      
      tradingRange = PriceInformation[HighestCandle].high - PriceInformation[LowestCandle].low;
      highestRange = MathMax(highestRange, tradingRange);
      lowestRange = MathMin(lowestRange, tradingRange);
      
      //int highest
      
      Print("Price Information High: ", PriceInformation[HighestCandle].high);
      Print("Price Information Low: ", PriceInformation[LowestCandle].low);
      
      Print("TradingRange: ", tradingRange);
      
      Comment("The current trading range: ", tradingRange);
      
      if(tradingRange <= lowestRange && status == 2){
      
         ObjectCreate(Symbol(), IntegerToString(time), OBJ_ARROW_UP, 0, TimeCurrent(), (PriceInformation[LowestCandle].low));
         ObjectSetInteger(Symbol(), IntegerToString(time), OBJPROP_COLOR, clrGreen);
         ObjectSetInteger(Symbol(), IntegerToString(time), OBJPROP_WIDTH, 3);
         status = 1;
      }
   
   
      if(tradingRange >= highestRange && status == 1){
      
         ObjectCreate(Symbol(), IntegerToString(time), OBJ_ARROW_DOWN, 0, TimeCurrent(), (PriceInformation[HighestCandle].high));
         ObjectSetInteger(Symbol(), IntegerToString(time), OBJPROP_COLOR, clrRed);
         ObjectSetInteger(Symbol(), IntegerToString(time), OBJPROP_WIDTH, 3);
         status = 2;
      }
      count++;
      
      if(count >= 10) count = 1;
      
      if(count == 10){
         highestRange = 0;
         lowestRange = 0;
         
      }
   }
}

         ObjectCreate(0, IntegerToString(timestamp), OBJ_ARROW_UP, 0, TimeCurrent(), (FastMovingAverageArray[1]));
         ObjectSetInteger(0, IntegerToString(timestamp), OBJPROP_COLOR, clrGreen);
         ObjectSetInteger(0, IntegerToString(timestamp), OBJPROP_WIDTH, 3);
         
         
         
         ObjectCreate(0, IntegerToString(timestamp), OBJ_ARROW_DOWN, 0, TimeCurrent(), (FastMovingAverageArray[1]));
         ObjectSetInteger(0, IntegerToString(timestamp), OBJPROP_COLOR, clrRed);
         ObjectSetInteger(0, IntegerToString(timestamp), OBJPROP_WIDTH, 3);
         


//+------------------------------------------------------------------+
//|                                                         MACO.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "© OPA Inc, 2020."
#property link      "lekepeterabiodun@gmail.com"
#property version   "1.00"
//---
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "ColorLine"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3

input int inpFastMA = 14; // Fast Moving Average
input int inpSlowMA = 50; // Slow Moving Average

double         MABuffer[];

double lineBuffer[];

//int OnInit()
//{
//
//   SetIndexBuffer(0,lineBuffer,INDICATOR_DATA);
//   PlotIndexSetInteger(0, PLOT_SHIFT, 0);
//   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, 3);
//   //PlotIndexSetInteger(0,PLOT_ARROW,159);
//   return (INIT_SUCCEEDED);
//}

//int OnCalculate(const int rates_total,
//                const int prev_calculated,
//                const int begin,
//                const double &price[]
//                )
//{
//   int bar = 0;
//   for(bar=0; bar<rates_total; bar++)
//   {
//      lineBuffer[bar]=price[bar];
//   
//   }
//   return(rates_total);
//}


void OnInit() 
  { 
//--- Bind the Array to the indicator buffer with index 0 
   SetIndexBuffer(0,MABuffer,INDICATOR_DATA); 
//--- Set the line drawing 
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_LINE); 
//--- Set the style line 
   //PlotIndexSetInteger(0,PLOT_LINE_STYLE,STYLE_DOT); 
//--- Set line color 
   //PlotIndexSetInteger(0,PLOT_LINE_COLOR,clrLime); 
//--- Set line thickness 
   //PlotIndexSetInteger(0,PLOT_LINE_WIDTH,3); 
//--- Set labels for the line 
   //PlotIndexSetString(0,PLOT_LABEL,"Moving Average"); 
//--- 
  } 
  
int OnCalculate(const int rates_total, 
                 const int prev_calculated, 
                 const datetime &time[], 
                 const double &open[], 
                 const double &high[], 
                 const double &low[], 
                 const double &close[], 
                 const long &tick_volume[], 
                 const long &volume[], 
                 const int &spread[]) 
  { 
//---  
   for(int i=prev_calculated;i<rates_total;i++) 
     { 
      MABuffer[i]=close[i]; 
     } 
//--- return value of prev_calculated for next call 
   return(rates_total); 
  }



    
    MqlRates PriceInformation[];
    ArraySetAsSeries(PriceInformation, true);
    int data = CopyRates(Symbol(), Period(), 0, 2, PriceInformation);
    
    double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), Digits());
    double bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
    double volatility = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_PRICE_VOLATILITY), _Digits);
    Print("Ask Price: ", ask);
    Print("Bid Price: ", bid);
    Print("Spread Price: ", ask-bid);
    Print("Volatility: ", volatility);
    Print("Symbol: ", Symbol());
    Print("Period: ", Period());
    Print("Digit Point: ", Digits());
    
    if(timestamp_1 != time_1){ 
        timestamp_1 = time_1;
        
        MqlRates PriceInformation[];
        ArraySetAsSeries(PriceInformation, true);
        int data = CopyRates(Symbol(), Period(), 0, 3, PriceInformation);
        
        int counter = 0;
        if(PriceInformation[1].close > PriceInformation[1].open)
        {
            counter++;
            
        }
        
        highest_spike = MathMax(counter, highest_spike);
        lowest_spike = MathMin(counter, 10);
        market_days++;
        spike = 0;
   }


###################################################################################################################
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
double total_sell_D1 = 0;
double total_buy_D1 = 0;
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
    Print("Total Buy & Sell Pips D1: ", total_buy_sell_D1);
    Print("Open Price of the day: ", opening_price_of_day);
    Print("Close Price of the day: ", close_price);
    //Print("Price difference: ", close_price);
    
    Print("Lowest SPike: ", lowest_spike);
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
            ObjectCreate(Symbol(), (PriceInformation[1].high), OBJ_ARROW_DOWN, 0, PriceInformation[1].time, (PriceInformation[1].high+2));
            ObjectSetInteger(Symbol(), (PriceInformation[1].high), OBJPROP_COLOR, clrGreen);
            ObjectSetInteger(Symbol(), (PriceInformation[1].high), OBJPROP_WIDTH, 3);
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
            ObjectSetInteger(Symbol(), (PriceInformation[1].high), OBJPROP_COLOR, clrRed);
        }
        total_candle++;
        open_price = PriceInformation[1].open;
        close_price = PriceInformation[1].close;
     }
   
   datetime time_1 = iTime(Symbol(), PERIOD_D1, 0);
   
   if(timestamp_1 != time_1){ 
        timestamp_1 = time_1;
        highest_spike = MathMax(spike, highest_spike);
        if(spike > 100) lowest_spike = MathMin(spike, 125);
        market_days++;
        spike = 0;
   }
   
//   datetime time_24 = iTime(Symbol(), PERIOD_D1, 0);
//   
//   if(timestamp_24 != time_24){ 
//        timestamp_24 = time_24;
//        highest_spike = MathMax(spike, highest_spike);
//        lowest_spike = MathMin(spike, 1000);
//        market_days++;
//        spike = 0;
//   }
   

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


###################################################################################################################
