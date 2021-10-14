
input group                                       "============  RSI Settings  ===============";
input bool                                         RSIFactor = true; // Use RSI
input ENUM_TIMEFRAMES                              RSITimeframe = PERIOD_CURRENT; // RSI Timeframe
input int                                          RSIPeriod = 9; // RSI Period
input ENUM_APPLIED_PRICE                           RSIAppliedPrice = PRICE_CLOSE; // RSI Applied Price
input int                                          overSoldLevel = 30; // RSI Oversold Level
input int                                          overBoughtLevel = 70; // RSI Overbought Level

int RSIHandle = iRSI(Symbol(), RSITimeframe, RSIPeriod, RSIAppliedPrice);
bool rsi_signal(marketSignal signal){
   if(!RSIFactor) return true;
   double RSIArray[];
   ArraySetAsSeries(RSIArray, true);
   CopyBuffer(RSIHandle, 0, 1, 3, RSIArray);
   double RSIValue = NormalizeDouble(RSIArray[0],2);
   Print("RSI Value:", RSIValue);
   if(signal == BUY && RSIValue <= overSoldLevel) { return true; }
   else if(signal == SELL && RSIValue >= overBoughtLevel) { return true; }
   return false;
}
