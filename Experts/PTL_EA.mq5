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

input group                                       "============  Position Management Settings ===============";
input bool                                         closeOnOppositeSignal = true; // Close Trade on Opposite Signal

input group                                       "============  Money Management Settings ===============";
input double                                       lotSize=0.1; // Lot Size
input double                                       stopLoss = 0.0; // Stop Loss in Pips
input double                                       takeProfit = 0.0; // Take Profit in Pips

input group                                       "============ Trail Stop Loss ===============";
input bool                                         trailStopLoss=false; //Trailing Stop Loss
input double                                       trailStep=0.0; //Trailing Step in Pips

input group                                       "============  Break Even ===============";
input bool                                         breakEven = false; // Break Even
input double                                       breakEvenPoint = 0.0; // Break Even in Pips

input group                                       "============   Master PTL Settings ===============";
input bool masterTrend = false; // Use Master Trend 
input ENUM_TIMEFRAMES masterTimeFrame = PERIOD_M15; // Master Trend Timeframe
input int inpMasterFastLength = 3; // Fast length
input int inpMasterSlowLength = 7; // Slow length

input group                                       "============ Slave PTL Settings ===============";
input int inpFastLength = 3; // Fast length
input int inpSlowLength = 7; // Slow length

input group                                       "============  Volatility Ratio Settings ===============";
input bool volatileFactor = false; // Use Volatility Ratio 
input int inpPeriod = 25; // Volatility Ratio Period 

int PTLHandle = iCustom(NULL, 0, "SPTL2", inpFastLength, inpSlowLength);
int VRHandle = iCustom(NULL, 0, "VolatilityRatio", inpPeriod);

void OnTick(){

   datetime time = iTime(_Symbol, _Period, 0);
   
   if(timestamp != time) {
      timestamp = time;

      if(marketSignal(Buy)){
         if(closeOnOppositeSignal && noOpenTrade(POSITION_TYPE_BUY)) { trade.PositionClose(PositionGetSymbol(0)); }
         if( marketTrend(Bullish) && marketVolatile() ) {  if(tradeBehaviour == Regular || tradeBehaviour == Long){ takeTrade(Buy); }  } 
         Print("Buy Signal");
      }
      else if(marketSignal(Sell)){
         if(closeOnOppositeSignal && noOpenTrade(POSITION_TYPE_SELL)) { trade.PositionClose(PositionGetSymbol(0)); }
         if( marketTrend(Bearish) && marketVolatile() ) {  if(tradeBehaviour == Regular || tradeBehaviour == Short){ takeTrade(Sell); } }
         Print("Sell Signal");
      }
      else { Print("No Signal"); }     
   }

}

bool marketSignal(enumTradeType signal)
{
   double up[], down[], PTLArray[];
   ArraySetAsSeries(up, true);
   ArraySetAsSeries(down, true);
   ArraySetAsSeries(PTLArray, true);
   CopyBuffer(PTLHandle,5,1,3,up); 
   CopyBuffer(PTLHandle,6,1,3,down);
   CopyBuffer(PTLHandle,7,1,3,PTLArray);
   bool _Buy  = (MathMax(up[0],down[0]) < iOpen(NULL,Period(),1) && MathMax(up[1],down[1]) >= iOpen(NULL,Period(),2));  
   bool _Sell = (MathMin(up[0],down[0]) > iOpen(NULL,Period(),1) && MathMin(up[1],down[1]) <= iOpen(NULL,Period(),2));
   if(signal == Buy && PTLArray[0] != EMPTY_VALUE && _Buy) { return true; }
   if(signal == Sell && PTLArray[0] != EMPTY_VALUE && _Sell) { return true; }
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

bool marketVolatile(){
   if(!volatileFactor){ return true; }
   double VRArray[];
   ArraySetAsSeries(VRArray, true);
   CopyBuffer(VRHandle,0,1,3,VRArray);
   if(VRArray[0] >= 1 ) { return true; }
   return false;
}

bool marketTrend(enumMarketTrend trend){
   Print("From Master Trend");
   if(!masterTrend) return true;
   double up[], down[], PTLArray[];
   ArraySetAsSeries(up, true);
   ArraySetAsSeries(down, true);
   ArraySetAsSeries(PTLArray, true);
   int PTLMasterHandle = iCustom(NULL, masterTimeFrame, "MPTL2", inpMasterFastLength, inpMasterSlowLength);
   CopyBuffer(PTLMasterHandle,5,1,3,up); 
   CopyBuffer(PTLMasterHandle,6,1,3,down);
   CopyBuffer(PTLMasterHandle,7,1,3,PTLArray);
   bool _Bullish  = (MathMax(up[0],down[0]) < iOpen(NULL,masterTimeFrame,1) && MathMax(up[1],down[1]) >= iOpen(NULL,masterTimeFrame,2));  
   bool _Bearish = (MathMin(up[0],down[0]) > iOpen(NULL,masterTimeFrame,1) && MathMin(up[1],down[1]) <= iOpen(NULL,masterTimeFrame,2));
   if(trend == Bullish && _Bullish) { Print("From Master Trend: Buy"); return true; }
   if(trend == Bearish && _Bearish) { Print("From Master Trend: Sell"); return true; }
   Print("From Master Trend: No Signal");
   return false;
}

bool noOpenTrade(ENUM_POSITION_TYPE positionType){
   if(!PositionsTotal()) return true;
   PositionGetSymbol(0);         
   if(PositionGetInteger(POSITION_TYPE) == positionType) return false;
   return true;
}

