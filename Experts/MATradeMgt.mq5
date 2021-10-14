#include <Trade\Trade.mqh>

input group                                        "============  EA Settings  ===============";
input ulong                                        EXPERT_MAGIC = 787878; // Magic Number

input group                                       "============  Moving Average Settings  ===============";
input int                                          fastMA = 1; // Fast Moving Average
input int                                          fastMAShift = 0; // Fast Moving Average Shift
input ENUM_MA_METHOD                               fastMAMethod = MODE_LWMA; // Fast Moving Average Method
input ENUM_APPLIED_PRICE                           fastMAAppliedPrice = PRICE_CLOSE; // Fast Moving Average Applied Price
input int                                          slowMA = 50; // Slow Moving Average
input int                                          slowMAShift = 0; // SLow Moving Average Shift
input ENUM_MA_METHOD                               slowMAMethod = MODE_LWMA; // Slow Moving Average Method
input ENUM_APPLIED_PRICE                           slowMAAppliedPrice = PRICE_LOW; // Slow Moving Average Applied Price

input group                                       "============  Position Management Settings ===============";
input bool                                         closeOnOppositeSignal = true; // Close Trade on Opposite Signal


int FastMovingAverageHandle = iMA(_Symbol, _Period, fastMA, fastMAShift, fastMAMethod, fastMAAppliedPrice);
int SlowMovingAverageHandle = iMA(_Symbol, _Period, slowMA, slowMAShift, slowMAMethod, slowMAAppliedPrice);

enum enumTradeType{Buy, Sell};

static datetime timestamp;

CTrade trade;


int OnInit() {
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {

}

void OnTick() {
   
   datetime time = iTime(_Symbol, _Period, 0);

   if(timestamp != time) {
         
      timestamp = time;
      
      if(marketSignal(Buy) && closeOnOppositeSignal) 
      { 
         trade.SetExpertMagicNumber(EXPERT_MAGIC);
         trade.PositionClose(PositionGetSymbol(0));
      } 
      else if(marketSignal(Sell) && closeOnOppositeSignal)  
      { 
         trade.SetExpertMagicNumber(EXPERT_MAGIC);
         trade.PositionClose(PositionGetSymbol(0)); 
      }
   }

}

bool marketSignal(enumTradeType signal ){
   double FastMovingAverageArray[];
   double SlowMovingAverageArray[];
   ArraySetAsSeries(FastMovingAverageArray, true);
   ArraySetAsSeries(SlowMovingAverageArray, true);
   CopyBuffer(FastMovingAverageHandle, 0, 1, 2, FastMovingAverageArray);
   CopyBuffer(SlowMovingAverageHandle, 0, 1, 2, SlowMovingAverageArray);
   if(signal == Buy){ if(FastMovingAverageArray[0] > SlowMovingAverageArray[0] && FastMovingAverageArray[1] < SlowMovingAverageArray[1]) return true; }
   if(signal == Sell){ if(FastMovingAverageArray[0] < SlowMovingAverageArray[0] && FastMovingAverageArray[1] > SlowMovingAverageArray[1]) return true; }
   return false;
}
