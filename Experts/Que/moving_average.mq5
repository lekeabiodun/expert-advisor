
input group                                       "============  Moving Average Settings  ===============";
input int                                          fastMA = 1; // Fast Moving Average
input int                                          fastMAShift = 0; // Fast Moving Average Shift
input ENUM_MA_METHOD                               fastMAMethod = MODE_LWMA; // Fast Moving Average Method
input ENUM_APPLIED_PRICE                           fastMAAppliedPrice = PRICE_CLOSE; // Fast Moving Average Applied Price
input int                                          slowMA = 45; // Slow Moving Average
input int                                          slowMAShift = 0; // Slow Moving Average Shift
input ENUM_MA_METHOD                               slowMAMethod = MODE_LWMA; // Slow Moving Average Method
input ENUM_APPLIED_PRICE                           slowMAAppliedPrice = PRICE_LOW; // Slow Moving Average Applied Price
int FastMovingAverageHandle = iMA(Symbol(), Period(), fastMA, fastMAShift, fastMAMethod, fastMAAppliedPrice);
int SlowMovingAverageHandle = iMA(Symbol(), Period(), slowMA, slowMAShift, slowMAMethod, slowMAAppliedPrice);

bool moving_average_signal(marketSignal signal){
    double FastMovingAverageArray[];
    double SlowMovingAverageArray[];
    ArraySetAsSeries(FastMovingAverageArray, true);
    ArraySetAsSeries(SlowMovingAverageArray, true);
    CopyBuffer(FastMovingAverageHandle, 0, 1, 2, FastMovingAverageArray);
    CopyBuffer(SlowMovingAverageHandle, 0, 1, 2, SlowMovingAverageArray);
    if(signal == BUY && FastMovingAverageArray[0] > SlowMovingAverageArray[0]) 
    { 
        return true; 
    }
    else if(signal == SELL && FastMovingAverageArray[0] < SlowMovingAverageArray[0]) 
    { 
        return true; 
    }
    return false;
}
