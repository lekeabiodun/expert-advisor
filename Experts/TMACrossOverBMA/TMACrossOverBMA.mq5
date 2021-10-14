
int SlowMovingAverageHandle = iMA(_Symbol, _Period, 50, 0, MODE_LWMA, PRICE_CLOSE);
static datetime timestamp;
void OnTick(){

   datetime time = iTime(_Symbol, _Period, 0);
   
   if(timestamp != time) {
   
      timestamp = time;
      
      double SlowMovingAverageArray[];
      ArraySetAsSeries(SlowMovingAverageArray, true);
      CopyBuffer(SlowMovingAverageHandle, 0, 1, 2, SlowMovingAverageArray);
      
      MqlRates PriceInformation[];
      
      ArraySetAsSeries(PriceInformation, true);
      
      CopyRates(_Symbol, _Period, 0, Bars(_Symbol, _Period), PriceInformation);
      
      //Print("Price: ", PriceInformation[1].close);
      //Print("MA: ", SlowMovingAverageArray[1]);
      
      if(PriceInformation[1].close < SlowMovingAverageArray[1]) Print("Sell Trend");
      if(PriceInformation[1].close > SlowMovingAverageArray[1]) Print("Buy Trend");
   }
   
}