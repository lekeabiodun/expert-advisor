input group                                       "============  Williams Percentage Settings  ===============";
input bool                                         wprFactor = true; // Use Trix 
input int                                          wprPeriod = 100; // Trix EMA Period

bool wpr_signal(marketSignal signal){
   if(!wprFactor) return true;
   int wprHandle = iWPR(_Symbol, Period(), wprPeriod);
   double wprArray[];
   ArraySetAsSeries(wprArray, true);
   CopyBuffer(trixHandle, 0, 0, 2, wprArray);
   if(signal == BUY && ( wprArray[0] > -80.0 || wprArray[0] > wprArray[1]) ) 
    { 
        return true; 
    }
    if(signal == SELL && (wprArray[0] < -20.0 || wprArray[0] < wprArray[1]) ) 
    { 
        return true; 
    }
   return false;
}