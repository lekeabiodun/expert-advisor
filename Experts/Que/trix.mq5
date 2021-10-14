input group                                       "============  Trix Settings  ===============";
input bool                                         trixFactor = true; // Use Trix 
input ENUM_TIMEFRAMES                              trixTimeframe = PERIOD_CURRENT; // Trix Timeframe
input int                                          trixPeriod = 14; // Trix EMA Period
input ENUM_APPLIED_PRICE                           trixPrice = PRICE_CLOSE; // Trix Applied Price

bool trix_signal(marketSignal signal){
   if(!trixFactor) return true;
   int trixHandle = iTriX(_Symbol, trixTimeframe, trixPeriod, trixPrice);
   double trixArray[];   
   ArraySetAsSeries(trixArray, true);
   CopyBuffer(trixHandle, 0, 0, 2, trixArray);
   if(signal == BUY && ( trixArray[0] > 0.0 || trixArray[0] < trixArray[1]) ) 
    { 
        return true; 
    }
    if(signal == SELL && (trixArray[0] < 0.0 || trixArray[0] > trixArray[1]) ) 
    { 
        return true; 
    }
   return false;
}