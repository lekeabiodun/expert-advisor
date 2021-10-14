#include <Trade\Trade.mqh>

enum enumTradeBehaviour{   
   Regular, // Take Regular trade
   Long, // Only Long
   Short // Only Short
};
enum enumTradeType{Buy, Sell};
enum enumMarketTrend{Bullish, Bearish, Sideway};
static datetime timestamp;
CTrade trade;

input group                                        "============  EA Settings  ===============";
input int                                          magicalNumber = 2390784; // Magic Number
input enumTradeBehaviour                           tradeBehaviour = Regular; // Trading Behaviour

input group                                       "============  Trend Moving Average Settings  ===============";
input bool                                         trendFactor = true; // Use Trend Moving Average
input ENUM_TIMEFRAMES                              trendTimeframe = PERIOD_CURRENT; // Trend Timeframe
input int                                          fastMasterMA = 1; // Trend Fast Moving Average
input int                                          fastMasterMAShift = 0; // Trend Fast Moving Average Shift
input ENUM_MA_METHOD                               fastMasterMAMethod = MODE_LWMA; // Trend Fast Moving Average Method
input ENUM_APPLIED_PRICE                           fastMasterMAAppliedPrice = PRICE_CLOSE; // Trend Fast Moving Average Applied Price
input int                                          slowMasterMA = 50; // Trend Slow Moving Average
input int                                          slowMasterMAShift = 0; // Trend Slow Moving Average Shift
input ENUM_MA_METHOD                               slowMasterMAMethod = MODE_LWMA; // Trend Slow Moving Average Method
input ENUM_APPLIED_PRICE                           slowMasterMAAppliedPrice = PRICE_LOW; // Trend Slow Moving Average Applied Price

input group                                       "============  Moving Average Settings  ===============";
input int                                          fastMA = 3; // Fast Moving Average
input int                                          fastMAShift = 0; // Fast Moving Average Shift
input ENUM_MA_METHOD                               fastMAMethod = MODE_LWMA; // Fast Moving Average Method
input ENUM_APPLIED_PRICE                           fastMAAppliedPrice = PRICE_CLOSE; // Fast Moving Average Applied Price
input int                                          slowMA = 5; // Slow Moving Average
input int                                          slowMAShift = 0; // SLow Moving Average Shift
input ENUM_MA_METHOD                               slowMAMethod = MODE_LWMA; // Slow Moving Average Method
input ENUM_APPLIED_PRICE                           slowMAAppliedPrice = PRICE_LOW; // Slow Moving Average Applied Price

input group                                       "============  Position Management Settings ===============";
input bool                                         closeOnOppositeSignal = true; // Close Trade on Opposite Signal

input group                                       "============  Money Management Settings ===============";
input double                                       lotSize=0.1; // Lot Size
input double                                       stopLoss = 2.0; // Stop Loss in Pips
input double                                       takeProfit = 3.0; // Take Profit in Pips

input group                                       "============ Trail Stop Loss ===============";
input bool                                         trailStopLoss=false; //Trailing Stop Loss
input double                                       trailStep=0.0; //Trailing Step in Pips

input group                                       "============  Break Even ===============";
input bool                                         breakEven = false; // Break Even
input double                                       breakEvenPoint = 0.0; // Break Even in Pips

int FastMovingAverageHandle = iMA(_Symbol, _Period, fastMA, fastMAShift, fastMAMethod, fastMAAppliedPrice);
int SlowMovingAverageHandle = iMA(_Symbol, _Period, slowMA, slowMAShift, slowMAMethod, slowMAAppliedPrice);

void OnTick(){

   datetime time = iTime(_Symbol, _Period, 0);
   
   if(timestamp != time) {
         
      timestamp = time;
      
      if(marketSignal(Buy)) {
         Print("Buy Signal");
         if(tradeBehaviour == Regular || tradeBehaviour == Long){ takeTrade(Buy); }
      } 
      else if(marketSignal(Sell)) {
         Print("Sell Signal");
         if(closeOnOppositeSignal){ trade.PositionClose(PositionGetSymbol(0)); }
         if(tradeBehaviour == Regular || tradeBehaviour == Short){ takeTrade(Sell); }
      } 
      else {
         Print("No Signal");
      }
      if(trailStopLoss && PositionsTotal()){ trailTrade(); }
      if(breakEven && PositionsTotal()){ tradeBreakEven(); }
   }
  
}

bool marketSignal(enumTradeType signal ){

   if(signal == Buy){
      if(movingAverageCrossOver(Buy)) {
         if(closeOnOppositeSignal){ trade.PositionClose(PositionGetSymbol(0)); }
         if(marketTrend(Bullish)) return true;
      }
      return false;
   }

   else if(signal == Sell ){
      if(movingAverageCrossOver(Sell)) {
         if(closeOnOppositeSignal){ trade.PositionClose(PositionGetSymbol(0)); }
         if(marketTrend(Bearish)) return true;
      }
      return false;
   }
   return false;
}

bool movingAverageCrossOver(enumTradeType signal ){
   double FastMovingAverageArray[];
   double SlowMovingAverageArray[];
   ArraySetAsSeries(FastMovingAverageArray, true);
   ArraySetAsSeries(SlowMovingAverageArray, true);
   CopyBuffer(FastMovingAverageHandle, 0, 1, 2, FastMovingAverageArray);
   CopyBuffer(SlowMovingAverageHandle, 0, 1, 2, SlowMovingAverageArray);

   if(signal == Buy){
      if(FastMovingAverageArray[0] > SlowMovingAverageArray[0] && FastMovingAverageArray[1] < SlowMovingAverageArray[1]) return true;
      return false;
   }
   else if(signal == Sell){
      if(FastMovingAverageArray[0] < SlowMovingAverageArray[0] && FastMovingAverageArray[1] > SlowMovingAverageArray[1]) return true;
      return false;
   }
   return false;
}

void takeTrade(enumTradeType tradeType) {
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   if(tradeType == Buy){
       trade.Buy(lotSize, _Symbol, Bid, setStopLoss(Bid, Buy), setTakeProfit(Bid, Buy), "-----Buying----");
   }
   if(tradeType == Sell){
       trade.Sell(lotSize, _Symbol, Bid, setStopLoss(Bid, Sell), setTakeProfit(Bid, Sell), "-----Selling-----");
   }
}

void tradeBreakEven(){
   string trade_0 = PositionGetSymbol(0);
   if( trade_0 != "" ) {
      if( (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) ) {
         if( (PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN))  >= breakEvenPoint ) {
            trade.PositionModify(trade_0, PositionGetDouble(POSITION_PRICE_OPEN), setTakeProfit(PositionGetDouble(POSITION_PRICE_OPEN), Buy));
         }
      }
      else if( (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL) ) {
         if( (PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT))  >= breakEvenPoint ) {
            trade.PositionModify(trade_0, PositionGetDouble(POSITION_PRICE_OPEN), setTakeProfit(PositionGetDouble(POSITION_PRICE_OPEN), Sell));
         }
      }
   }
}

bool marketTrend(enumMarketTrend trend){
   if(!trendFactor) return true;
   int FastMasterMovingAverageHandle = iMA(_Symbol, trendTimeframe, fastMasterMA, fastMasterMAShift, fastMasterMAMethod, fastMasterMAAppliedPrice);
   int SlowMasterMovingAverageHandle = iMA(_Symbol, trendTimeframe, slowMasterMA, slowMasterMAShift, slowMasterMAMethod, slowMasterMAAppliedPrice);
   double FastMasterMovingAverageArray[];
   double SlowMasterMovingAverageArray[];
   ArraySetAsSeries(FastMasterMovingAverageArray, true);
   ArraySetAsSeries(SlowMasterMovingAverageArray, true);
   CopyBuffer(FastMasterMovingAverageHandle, 0, 1, 2, FastMasterMovingAverageArray);
   CopyBuffer(SlowMasterMovingAverageHandle, 0, 1, 2, SlowMasterMovingAverageArray);
   if(trend == Bullish && FastMasterMovingAverageArray[0] > SlowMasterMovingAverageArray[0]) { return true; }
   else if(trend == Bearish && FastMasterMovingAverageArray[0] < SlowMasterMovingAverageArray[0]) { return true; }
   return false;
}

double setStopLoss(double Bid, enumTradeType tradeType){
   if(!stopLoss){ return 0.0; }
   return calculateStopLoss(Bid, tradeType);
}

double calculateStopLoss(double Bid, enumTradeType tradeType){
   if(tradeType == Buy){ return Bid-stopLoss; }
   if(tradeType == Sell){ return Bid+stopLoss; }
   return 0.0;
}

double setTakeProfit(double Bid, enumTradeType tradeType){
   if(!takeProfit){ return 0.0; }
   return calculateTakeProfit(Bid, tradeType);
}

double calculateTakeProfit(double Bid, enumTradeType tradeType){
   if(tradeType == Buy){ return  Bid+takeProfit; }
   if(tradeType == Sell){ return Bid-takeProfit; } 
   return 0.0;
}

void trailTrade(){
   string trade_0 = PositionGetSymbol(0);
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   Print("Bid Price: ", Bid);
   Print("Open Price: ", PositionGetDouble(POSITION_PRICE_OPEN));
   if( trade_0 != "" ) {
      if( (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) ) {
         if(!PositionGetDouble(POSITION_SL)){
            trade.PositionModify(trade_0, calculateStopLoss(PositionGetDouble(POSITION_PRICE_OPEN), Buy), setTakeProfit(PositionGetDouble(POSITION_PRICE_OPEN), Buy));
         }

         if( (PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_SL))  < trailStep ) {
            trade.PositionModify(trade_0, PositionGetDouble(POSITION_PRICE_CURRENT)-trailStep, setTakeProfit(PositionGetDouble(POSITION_PRICE_OPEN), Buy));
         }
      }

      else if( (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL) ) {
         if(!PositionGetDouble(POSITION_SL)){
               Print("Stop Loss Set @open: ", PositionGetDouble(POSITION_PRICE_OPEN), " @SL: ", calculateStopLoss(PositionGetDouble(POSITION_PRICE_OPEN), Sell));
               trade.PositionModify(trade_0, calculateStopLoss(PositionGetDouble(POSITION_PRICE_OPEN), Sell), setTakeProfit(PositionGetDouble(POSITION_PRICE_OPEN), Sell));
            } 
         if( (PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_SL))  < trailStep ) {
            trade.PositionModify(trade_0, PositionGetDouble(POSITION_PRICE_CURRENT)+trailStep, setTakeProfit(PositionGetDouble(POSITION_PRICE_OPEN), Sell));
         }
      }
   }
}