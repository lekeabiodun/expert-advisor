input group                                       "============ Volatility Ratio Settings ===============";
input int                                         volatilityRatioPeriod = 25; // Volatility Ratio Period
input double                                      volatilityRatioOverbought = 1.0; // Volatility Ratio Overbought
input double                                      volatilityRatioOversold = 0.2; // Volatility Ratio Oversold
int volatilityRatioHandle = iCustom(NULL, 0, "VolatilityRatio", volatilityRatioPeriod);

bool volatility_ratio_signal(marketSignal signal)
{
    double volatilityRatioArray[];
    ArraySetAsSeries(volatilityRatioArray, true);
    CopyBuffer(volatilityRatioHandle, 0, 0, 3, volatilityRatioArray);
    if(signal == BUY && volatilityRatioArray[0] >= 1) 
    { 
        return true;  
    }
    if(signal == SELL && volatilityRatioArray[0] < 1) 
    { 
        return true;  
    }  
    return false;
}