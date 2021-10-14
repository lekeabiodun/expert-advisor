
input group                                       "============ Stochastic Volatility Settings ===============";
int stochasticVolatilityHandle = iCustom(Symbol(), Period(), "StochasticVolatility");

bool stochastic_volatility_signal(marketSignal signal)
{
    double up[], down[], stochSignal[];
    ArraySetAsSeries(up, true);
    ArraySetAsSeries(down, true);
    ArraySetAsSeries(stochSignal, true);
    CopyBuffer(stochasticVolatilityHandle, 0, 0, 3, up);
    CopyBuffer(stochasticVolatilityHandle, 1, 0, 3, down);
    CopyBuffer(stochasticVolatilityHandle, 2, 0, 3, stochSignal);
    if(signal == BUY && stochSignal[1] < stochSignal[0] && stochSignal[0] >= up[0]) 
    { 
        close_opposite_trade(LONG);
        return true;  
    }
    if(signal == SELL && stochSignal[1] > stochSignal[0] && stochSignal[0] < up[0] && stochSignal[0] > down[0]) 
    { 
        close_opposite_trade(SHORT);
        return true;  
    }  
    if(stochSignal[0] <= down[0]) 
    {
        close_all_positions();
    }
    return false;
}