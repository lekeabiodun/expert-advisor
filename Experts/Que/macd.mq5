
input group                                       "============  MACD Settings  ===============";
input bool                                         macdFactor = true; // Use signal MACD
input ENUM_TIMEFRAMES                              macdTimeframe = PERIOD_CURRENT; // Trend Timeframe
input int                                          macdFastEMA = 12; // Trend Fast EMA
input int                                          macdSlowEMA = 26; // Trend Slow EMA
input int                                          MACDSMA = 9; // Trend MACD SMA
input ENUM_APPLIED_PRICE                           MACDAppliedPrice = PRICE_CLOSE; // MACD Applied Price

bool macd_signal(marketSignal signal)
{
    if(!macdFactor) return true;
    int MACDHandle = iMACD(Symbol(), macdTimeframe, macdFastEMA, macdSlowEMA, MACDSMA, MACDAppliedPrice);
    double MACDArray[];
    ArraySetAsSeries(MACDArray, true);
    CopyBuffer(MACDHandle, 0, 0, 3, MACDArray);
    if(signal == BUY && MACDArray[0] > 0) 
    { 
        return true; 
    }
    else if(signal == SELL && MACDArray[0] < 0) 
    { 
        return true; 
    }
    return false;
}