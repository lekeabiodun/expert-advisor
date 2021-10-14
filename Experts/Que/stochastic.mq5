input group                                       "============  Stochastic Settings  ===============";
input int stoch_kperiod = 5; // % K Period
input int stoch_dperiod = 3; // % D Period
input int stoch_slowing = 3; // Slowing
input ENUM_STO_PRICE stoch_price = STO_LOWHIGH;  // Price Field
input ENUM_MA_METHOD stoch_mode = MODE_SMA; // Method



bool stochastic_signal(marketSignal signal)
{

    if(!stochFactor) return true;
    double KArray[], DArray[];
    ArraySetAsSeries(KArray, true);
    ArraySetAsSeries(DArray, true);      
    int Stochastic = iStochastic(_Symbol, _Period, stochKperiod, stochDperiod, stochSlowing, stochMode, stochPrice);
    CopyBuffer(Stochastic, 0, 0, 3, KArray);
    CopyBuffer(Stochastic, 1, 0, 3, DArray);
    if(signal == BUY && KArray[0] < oversold && DArray[0] < oversold && KArray[0] > DArray[0] && KArray[1] < DArray[1]) 
    {
        return true; 
    }
    if(signal == SELL && KArray[0] > overbought && DArray[0] > overbought && KArray[0] < DArray[0] && KArray[1] > DArray[1]) 
    {
        return true; 
    }
    return false;
}
