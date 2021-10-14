
#include <Trade\Trade.mqh>
CTrade trade;
static datetime timestamp;

enum marketSignal{
    BUY,                // BUY 
    SELL                // SELL
};

void OnTick()
{

   datetime time = iTime(Symbol(), Period(), 0);

   if(timestamp != time) {
        tradeManager();
        timestamp = time;
        if(ma_signal(BUY))
        {
           double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), _Digits);
           double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), _Digits);
           //trade.Buy(1, Symbol(), ask, ask-20, ask+20);
           trade.Sell(1, Symbol(), ask, 0, bid-20);
        }
        
   }

}



void tradeManager() {
    if(PositionsTotal()) {
        for(int i = PositionsTotal()-1; i >= 0; i--) {
            PositionGetSymbol(i);
            
            /*if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                if(PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) >= 20 ) {
                    trade.PositionClose(PositionGetSymbol(i));
                }
                if(PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) <= -20) {
                    trade.PositionClose(PositionGetSymbol(i));
                }
            }*/
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                //if(PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT) >= 20 ) {
                //    trade.PositionClose(PositionGetSymbol(i));
                //}
                if(PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) >= 20 ) {
                    trade.PositionClose(PositionGetSymbol(i));
                }
            }
        }
    }
}


input group                                       "============  Moving Average Settings  ===============";
input bool                                         maFactor = true; // Use Moving Average 
input int                                          fastMA = 1; // Fast Moving Average
input int                                          fastMAShift = 0; // Fast Moving Average Shift
input ENUM_MA_METHOD                               fastMAMethod = MODE_LWMA; // Fast Moving Average Method
input ENUM_APPLIED_PRICE                           fastMAAppliedPrice = PRICE_CLOSE; // Fast Moving Average Applied Price
input int                                          slowMA = 100; // Slow Moving Average
input int                                          slowMAShift = 0; // SLow Moving Average Shift
input ENUM_MA_METHOD                               slowMAMethod = MODE_LWMA; // Slow Moving Average Method
input ENUM_APPLIED_PRICE                           slowMAAppliedPrice = PRICE_LOW; // Slow Moving Average Applied Price
input ENUM_TIMEFRAMES                              maPeriod = PERIOD_M1; // Moving Average Period;

bool maBUY = false;
bool maSELL = false;

int FastMovingAverageHandle = iMA(Symbol(), maPeriod, fastMA, fastMAShift, fastMAMethod, fastMAAppliedPrice);
int SlowMovingAverageHandle = iMA(Symbol(), maPeriod, slowMA, slowMAShift, slowMAMethod, slowMAAppliedPrice);

bool ma_signal(marketSignal signal ){
    if(!maFactor) return true;
    double FastMovingAverageArray[];
    double SlowMovingAverageArray[];
    ArraySetAsSeries(FastMovingAverageArray, true);
    ArraySetAsSeries(SlowMovingAverageArray, true);
    CopyBuffer(FastMovingAverageHandle, 0, 0, 3, FastMovingAverageArray);
    CopyBuffer(SlowMovingAverageHandle, 0, 0, 3, SlowMovingAverageArray);
    if(signal == BUY && FastMovingAverageArray[0] > SlowMovingAverageArray[0] && !maBUY) {
        maBUY = true;
        return true; 
    } 
    if(FastMovingAverageArray[0] < SlowMovingAverageArray[0]) {
        maBUY = false;
        // return true; 
    }
    return false;
}



/*

int wprHandle = iWPR(Symbol(), Period(), 100);

bool wpr_signal(marketSignal signal){
   double wprArray[];
   ArraySetAsSeries(wprArray, true);
   CopyBuffer(wprHandle, 0, 0, 3, wprArray);
   if(signal == BUY && wprArray[0] > wprArray[1]) 
    { 
        return true; 
    }
    if(signal == SELL && wprArray[0] < wprArray[1]) 
    { 
        return true; 
    }

   return false;
}

int deMarkerHandle = iDeMarker(Symbol(), Period(), 14);

bool deMarker_signal(marketSignal signal)
{
   double deMarkerArray[];
   ArraySetAsSeries(deMarkerArray, true);
   CopyBuffer(deMarkerHandle, 0, 0, 3, deMarkerArray);
   if(signal == BUY && deMarkerArray[0] > deMarkerArray[1])
    {
        return true;
    }
    if(signal == SELL && deMarkerArray[0] < deMarkerArray[1])
    {
        return true;
    }
    return false;
}

*/