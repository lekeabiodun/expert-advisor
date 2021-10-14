#include <Trade\Trade.mqh>

enum s_ENUM_TRADE_MONEY_MANAGEMENT_BEHAVIOUR{ s_MANUALTRADE, s_MARTINGALE_ADD, s_MARTINGALE_MULT };
enum s_ENUM_TRADE_BEHAVIOUR{ s_REGULAR, s_INVERSE, s_LONG, s_SHORT };
enum s_ENUM_TRADE_TYPE{s_BUY, s_SELL};
static datetime timestamp;
CTrade trade;

input group                                        "============  EA Settings  ===============";
input int                                          magicalNumber = 2390784; // Magic Number
input s_ENUM_TRADE_BEHAVIOUR                       s_TRADE_BEHAVIOUR = s_REGULAR; // Trading Behaviour

input group                                       "============  Moving Average Settings  ===============";
input int                                          fastMA = 7; // Fast Moving Average
input int                                          fastMAShift = 0; // Fast Moving Average Shift
input ENUM_MA_METHOD                               fastMAMethod = MODE_LWMA; // Fast Moving Average Method
input ENUM_APPLIED_PRICE                           fastMAAppliedPrice = PRICE_LOW; // Fast Moving Average Applied Price
input int                                          slowMA = 19; // Slow Moving Average
input int                                          slowMAShift = 0; // SLow Moving Average Shift
input ENUM_MA_METHOD                               slowMAMethod = MODE_LWMA; // Slow Moving Average Method
input ENUM_APPLIED_PRICE                           slowMAAppliedPrice = PRICE_LOW; // Slow Moving Average Applied Price

input group                                       "============  Position Management Settings ===============";
input bool                                         closeOnOppositeSignal = true; // Close Trade on Opposite Signal

input group                                       "============  Money Management Settings ===============";
input double                                       lotSize=0.1; // Lot Size
input double                                       s_STOP_LOSS = 4293; // Stop Loss in Pips
input double                                       s_TAKE_PROFIT = 130000; // Take Profit in Pips
input double                                       s_BREAK_EVEN = 2293; // Break Even in Pips

int FastMovingAverageHandle = iMA(_Symbol, _Period, fastMA, fastMAShift, fastMAMethod, fastMAAppliedPrice);
int SlowMovingAverageHandle = iMA(_Symbol, _Period, slowMA, slowMAShift, slowMAMethod, slowMAAppliedPrice);

void OnTick(){

   datetime time = iTime(_Symbol, _Period, 0);
   
   if(timestamp != time) {
      manageMyMoney();
      timestamp = time;
      if(movingAverageCrossOverSignal(s_BUY)) {
         Comment("Buy Signal");
         if(closeOnOppositeSignal){ trade.PositionClose(PositionGetSymbol(0)); }
         if(s_TRADE_BEHAVIOUR == s_REGULAR || s_TRADE_BEHAVIOUR == s_LONG){ takeTrade(s_SELL); }
         else if(s_TRADE_BEHAVIOUR == s_INVERSE){ takeTrade(s_BUY); }
      } 
      else if(movingAverageCrossOverSignal(s_SELL)) {
         Comment("Sell Signal");
         if(closeOnOppositeSignal){ trade.PositionClose(PositionGetSymbol(0)); }
         if(s_TRADE_BEHAVIOUR == s_REGULAR || s_TRADE_BEHAVIOUR == s_SHORT){ takeTrade(s_BUY); }
         else if(s_TRADE_BEHAVIOUR == s_INVERSE){ takeTrade(s_SELL); }
      }
   }
  
}

bool movingAverageCrossOverSignal(s_ENUM_TRADE_TYPE s_TRADE_TYPE ){
   double FastMovingAverageArray[];
   double SlowMovingAverageArray[];
   ArraySetAsSeries(FastMovingAverageArray, true);
   ArraySetAsSeries(SlowMovingAverageArray, true);
   CopyBuffer(FastMovingAverageHandle, 0, 1, 2, FastMovingAverageArray);
   CopyBuffer(SlowMovingAverageHandle, 0, 1, 2, SlowMovingAverageArray);
   if(s_TRADE_TYPE == s_BUY){
      if(FastMovingAverageArray[0] > SlowMovingAverageArray[0] && FastMovingAverageArray[1] < SlowMovingAverageArray[1]) {
         return true;
      }
   }
   else if(s_TRADE_TYPE == s_SELL){
      if(FastMovingAverageArray[0] < SlowMovingAverageArray[0] && FastMovingAverageArray[1] > SlowMovingAverageArray[1]) {
         return true;
      }
   }
   return false;
}

void takeTrade(s_ENUM_TRADE_TYPE s_TRADE_TYPE) {
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   if(s_TRADE_TYPE == s_BUY){
       trade.Buy(lotSize, _Symbol, Bid, Bid-s_STOP_LOSS, Bid+s_TAKE_PROFIT, "-----Buying----");
   }
   if(s_TRADE_TYPE == s_SELL){
       trade.Sell(lotSize, _Symbol, Bid, Bid+s_STOP_LOSS, Bid-s_TAKE_PROFIT, "-----Selling-----");
   }
}


void manageMyMoney(){
   string trade_0 = PositionGetSymbol(0);
   if( trade_0 != "" ) {
      if( (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) ) {
         if( (PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN))  >= s_BREAK_EVEN ) {
            trade.PositionModify(trade_0, PositionGetDouble(POSITION_PRICE_OPEN), PositionGetDouble(POSITION_PRICE_OPEN)+s_TAKE_PROFIT);
         }
      }
      else if( (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL) ) {
         if( (PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT))  >= s_BREAK_EVEN ) {
            trade.PositionModify(trade_0, PositionGetDouble(POSITION_PRICE_OPEN), PositionGetDouble(POSITION_PRICE_OPEN)-s_TAKE_PROFIT);
         }
      }
   }
}
