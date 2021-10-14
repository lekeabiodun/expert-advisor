
input group                                       "============  Parabolic SAR Settings  ===============";
input double                                       step = 0.02; // Parabolic SAR Step | price increment step - acceleration factor 
input double                                       maximum = 0.2; // Parabolic SAR Maximum value of step 

int paraBolicSARHandle = iSAR(Symbol(), Period(), step, maximum);

bool parabolic_sar_signal(marketSignal signal){
    double parabolicSARArray[];
    ArraySetAsSeries(parabolicSARArray, true);
    CopyBuffer(paraBolicSARHandle, 0, 0, 3, parabolicSARArray);
    if(signal == BUY && parabolicSARArray[1] < iLow(Symbol(), Period(), 1)) 
    { 
        return true; 
    }
    else if(signal == SELL && parabolicSARArray[1] > iHigh(Symbol(), Period(), 1)) 
    { 
        return true; 
    }
    return false;
}

